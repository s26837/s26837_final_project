class EmailEvent < ApplicationRecord
  belongs_to :campaign_send

  validates :event_type, presence: true, inclusion: { in: %w[delivered opened clicked bounced] }
  validates :occurred_at, presence: true

  after_create_commit :broadcast_subscribed_views

  scope :opened, -> { where(event_type: 'opened') }
  scope :clicked, -> { where(event_type: 'clicked') }
  scope :delivered, -> { where(event_type: 'delivered') }
  scope :bounced, -> { where(event_type: 'bounced') }
  scope :recent, -> { order(occurred_at: :desc) }

  def contact
    campaign_send.contact
  end

  private

  def broadcast_subscribed_views
    return unless campaign_send
    CampaignSend.broadcast_subscribed_views_for(campaign_send)
  end
end
