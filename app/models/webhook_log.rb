class WebhookLog < ApplicationRecord
  validates :event_type, presence: true
  validates :payload, presence: true

  scope :unprocessed, -> { where(processed: false) }
  scope :processed, -> { where(processed: true) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  def process!
    return if processed?

    begin
      sendgrid_message_id = payload['sg_message_id']
      event_type = payload['event']
      occurred_at = payload['timestamp'] ? Time.at(payload['timestamp'].to_i) : Time.current

      campaign_send = CampaignSend.find_by(sendgrid_message_id: sendgrid_message_id)

      if campaign_send
        campaign_send.email_events.create!(
          event_type: event_type,
          occurred_at: occurred_at,
          url: payload['url'],
          user_agent: payload['useragent'],
          ip_address: payload['ip']
        )

        case event_type
        when 'delivered'
          campaign_send.mark_as_delivered!
        when 'bounce', 'dropped'
          campaign_send.mark_as_bounced!
        end
      end

      update!(processed: true)
    rescue => e
      Rails.logger.error("Failed to process webhook log #{id}: #{e.message}")
    end
  end

  def processed?
    processed
  end
end
