class ProcessSendgridEventJob < ApplicationJob
  queue_as :default

  def perform(event_data, webhook_log_id = nil)
    message_id = event_data['sg_message_id']
    campaign_send_id = event_data['campaign_send_id']
    
    campaign_send = if campaign_send_id.present?
      CampaignSend.find_by(id: campaign_send_id)
    elsif message_id.present?
      CampaignSend.find_by(sendgrid_message_id: message_id)
    end
    
    return unless campaign_send
    
    broadcast_type = nil

    ActiveRecord::Base.transaction do
      case event_data['event']
      when 'delivered'
        campaign_send.update!(status: 'delivered', delivered_at: Time.current)

      when 'open'
        campaign_send.email_events.create!(
          event_type: 'opened',
          occurred_at: Time.at(event_data['timestamp'].to_i),
          user_agent: event_data['useragent'],
          ip_address: event_data['ip']
        )
        broadcast_type = 'opened'

      when 'click'
        campaign_send.email_events.create!(
          event_type: 'clicked',
          occurred_at: Time.at(event_data['timestamp'].to_i),
          url: event_data['url'],
          user_agent: event_data['useragent'],
          ip_address: event_data['ip']
        )
        broadcast_type = 'clicked'

      when 'bounce'
        campaign_send.update!(status: 'bounced')

      when 'dropped'
        campaign_send.update!(status: 'failed')

      when 'spam_report'
        campaign_send.update!(status: 'spam')
      end

      WebhookLog.where(id: webhook_log_id).update_all(processed: true) if webhook_log_id
    end

    broadcast_event(campaign_send, broadcast_type) if broadcast_type

  rescue => e
    Rails.logger.error "Failed to process SendGrid event: #{e.message}"
  end

  private

  def broadcast_event(campaign_send, event_type)
    ActionCable.server.broadcast(
      "organization_#{campaign_send.campaign.organization_id}",
      {
        type: 'email_event',
        campaign_send_id: campaign_send.id,
        campaign_id: campaign_send.campaign_id,
        contact_id: campaign_send.contact_id,
        event_type: event_type,
        timestamp: Time.current.iso8601
      }
    )
  end
end
