class TrackingController < ApplicationController
  skip_before_action :require_authentication

  ALLOWED_SCHEMES = %w[http https mailto].freeze

  PIXEL_GIF = "GIF89a\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff\x00\x00\x00!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;".dup.force_encoding(Encoding::ASCII_8BIT).freeze

  def open
    campaign_send = CampaignSend.find_by(id: params[:campaign_send_id])
    if campaign_send
      campaign_send.email_events.create!(
        event_type: "opened",
        occurred_at: Time.current,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )
    end

    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    send_data PIXEL_GIF, type: "image/gif", disposition: "inline"
  end

  def click
    target = safe_url(params[:url])

    campaign_send = CampaignSend.find_by(id: params[:campaign_send_id])
    if campaign_send && target
      campaign_send.email_events.create!(
        event_type: "clicked",
        occurred_at: Time.current,
        url: target,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )
    end

    if target
      redirect_to target, allow_other_host: true
    else
      redirect_to root_path
    end
  end

  private

  def safe_url(raw)
    return nil if raw.blank?

    uri = URI.parse(raw.to_s)
    return nil unless ALLOWED_SCHEMES.include?(uri.scheme&.downcase)

    raw.to_s
  rescue URI::InvalidURIError
    nil
  end
end
