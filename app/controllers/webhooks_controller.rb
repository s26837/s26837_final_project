class WebhooksController < ApplicationController
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token

  before_action :verify_sendgrid_signature, only: [:sendgrid]

  SIGNATURE_HEADER  = 'X-Twilio-Email-Event-Webhook-Signature'.freeze
  TIMESTAMP_HEADER  = 'X-Twilio-Email-Event-Webhook-Timestamp'.freeze
  REPLAY_WINDOW_SEC = 5.minutes.to_i

  def sendgrid
    events = params[:_json] || [params]

    events.each do |event|
      payload = event.to_unsafe_h
      log = WebhookLog.create!(event_type: 'sendgrid', payload: payload)
      ProcessSendgridEventJob.perform_later(payload, log.id)
    end

    head :ok
  end

  private

  def verify_sendgrid_signature
    return if signature_valid?
    head :unauthorized
  end

  def signature_valid?
    public_key_pem = ENV['SENDGRID_WEBHOOK_PUBLIC_KEY']
    return true if public_key_pem.blank?

    signature_b64 = request.headers[SIGNATURE_HEADER]
    timestamp     = request.headers[TIMESTAMP_HEADER]
    return false if signature_b64.blank? || timestamp.blank?

    return false if (Time.current.to_i - timestamp.to_i).abs > REPLAY_WINDOW_SEC

    ec_key = OpenSSL::PKey::EC.new(public_key_pem)
    digest = OpenSSL::Digest::SHA256.digest("#{timestamp}#{request.raw_post}")
    ec_key.dsa_verify_asn1(digest, Base64.decode64(signature_b64))
  rescue OpenSSL::OpenSSLError, ArgumentError => e
    Rails.logger.warn "SendGrid signature verification error: #{e.message}"
    false
  end
end
