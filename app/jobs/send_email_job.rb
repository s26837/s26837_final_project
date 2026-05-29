require 'sendgrid-ruby'

class SendEmailJob < ApplicationJob
  include SendGrid

  queue_as :default

  FROM_EMAIL = 'noreply@pirita.shaderless.com'.freeze

  def perform(campaign_send_id)
    campaign_send = CampaignSend.find(campaign_send_id)
    campaign = campaign_send.campaign
    contact = campaign_send.contact

    api_key = campaign.organization.effective_sendgrid_key
    raise "No SendGrid API key configured for organization #{campaign.organization_id}" if api_key.blank?

    if campaign.organization.sendgrid_demo? && !DemoKeyUsage.increment_if_allowed!
      campaign_send.mark_as_failed!
      return
    end

    template = campaign_send.campaign_step&.email_template
    raise "Campaign send #{campaign_send.id} has no template" unless template

    subject = template.subject
    html_content = inject_tracking(template.html_content, campaign_send)
    text_content = template.text_content

    message_id = send_via_sendgrid(contact.email, subject, html_content, text_content, campaign_send, api_key)

    campaign_send.update!(
      status: 'sent',
      sendgrid_message_id: message_id,
      delivered_at: Time.current
    )

  rescue => e
    campaign_send.mark_as_failed!
    Rails.logger.error "Failed to send email: #{e.message}"
  end

  private

  def inject_tracking(html_content, campaign_send)
    return html_content if html_content.blank?

    app_url = ENV.fetch('APP_URL', 'http://localhost:3000')
    doc = Nokogiri::HTML::DocumentFragment.parse(html_content)

    doc.css('a[href]').each do |anchor|
      href = anchor['href']
      next if href.blank? || href.include?('track/')

      anchor['data-original-url'] = href
      anchor['href'] = "#{app_url}/track/#{campaign_send.id}?url=#{CGI.escape(href)}"
    end

    body = doc.to_html
    pixel = %(<img src="#{app_url}/track/open/#{campaign_send.id}" width="1" height="1" alt="" border="0" style="display:block;width:1px;height:1px;border:0;">)

    <<~HTML
      <!DOCTYPE html>
      <html><head><meta charset="utf-8"></head><body style="margin:0;padding:0;">#{body}#{pixel}</body></html>
    HTML
  end

  def send_via_sendgrid(to_email, subject, html_content, text_content, campaign_send, api_key)
    mail = Mail.new
    mail.from = Email.new(email: FROM_EMAIL)
    mail.subject = subject

    personalization = Personalization.new
    personalization.add_to(Email.new(email: to_email))
    mail.add_personalization(personalization)

    mail.add_content(Content.new(type: 'text/plain', value: text_content)) if text_content.present?
    mail.add_content(Content.new(type: 'text/html', value: html_content)) if html_content.present?

    mail.add_custom_arg(CustomArg.new(key: 'campaign_send_id', value: campaign_send.id.to_s))

    sg = SendGrid::API.new(api_key: api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    unless response.status_code.to_i.between?(200, 299)
      raise "SendGrid request failed (#{response.status_code}): #{response.body}"
    end

    response.headers['X-Message-Id']&.first || response.headers['x-message-id']&.first
  end
end
