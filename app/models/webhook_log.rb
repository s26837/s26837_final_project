class WebhookLog < ApplicationRecord
  validates :event_type, presence: true
  validates :payload, presence: true

  scope :unprocessed, -> { where(processed: false) }
  scope :processed, -> { where(processed: true) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  SENDGRID_EVENT_MAP = {
    'delivered' => 'delivered',
    'open'      => 'opened',
    'opened'    => 'opened',
    'click'     => 'clicked',
    'clicked'   => 'clicked',
    'bounce'    => 'bounced',
    'bounced'   => 'bounced',
    'dropped'   => 'bounced'
  }.freeze

  def process!
    return if processed?

    sendgrid_message_id = payload['sg_message_id']
    sendgrid_event      = payload['event']
    mapped_event        = SENDGRID_EVENT_MAP[sendgrid_event]
    occurred_at         = payload['timestamp'] ? Time.at(payload['timestamp'].to_i) : Time.current

    campaign_send = CampaignSend.find_by(sendgrid_message_id: sendgrid_message_id)

    if campaign_send && mapped_event
      campaign_send.email_events.create!(
        event_type: mapped_event,
        occurred_at: occurred_at,
        url: payload['url'],
        user_agent: payload['useragent'],
        ip_address: payload['ip']
      )

      case sendgrid_event
      when 'delivered'
        campaign_send.mark_as_delivered!
      when 'bounce', 'dropped'
        campaign_send.mark_as_bounced!
      end
    end

    update!(processed: true)
  end

  def processed?
    processed
  end
end
