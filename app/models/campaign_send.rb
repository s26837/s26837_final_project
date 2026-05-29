class CampaignSend < ApplicationRecord
  belongs_to :campaign
  belongs_to :campaign_step, optional: true
  belongs_to :contact

  has_many :email_events, dependent: :destroy
  has_many :automation_executions, dependent: :nullify

  validates :status, presence: true, inclusion: { in: %w[queued sent delivered failed bounced spam] }
  validates :campaign_step_id, uniqueness: { scope: :contact_id, allow_nil: true }

  before_create :set_default_status
  after_update_commit :broadcast_subscribed_views, if: :saved_change_to_status?

  scope :queued, -> { where(status: 'queued') }
  scope :sent, -> { where(status: 'sent') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }
  scope :bounced, -> { where(status: 'bounced') }
  scope :spam, -> { where(status: 'spam') }

  def opened?
    email_events.exists?(event_type: 'opened')
  end

  def clicked?
    email_events.exists?(event_type: 'clicked')
  end

  def bounced?
    status == 'bounced'
  end

  def delivered?
    status == 'delivered'
  end

  def mark_as_delivered!
    update!(status: 'delivered', delivered_at: Time.current)
  end

  def mark_as_failed!
    update!(status: 'failed')
  end

  def mark_as_bounced!
    update!(status: 'bounced')
  end

  def self.broadcast_subscribed_views_for(campaign_send)
    campaign = campaign_send.campaign
    contact  = campaign_send.contact

    Turbo::StreamsChannel.broadcast_replace_to(
      "campaign_#{campaign.id}",
      target: ActionView::RecordIdentifier.dom_id(campaign, :stats),
      partial: "campaigns/stats_tiles",
      locals: { campaign: campaign, stats: campaign.reload_stats }
    )

    activity = contact.campaign_sends
                      .includes(:email_events, :campaign, campaign_step: :email_template)
                      .order(created_at: :desc)
                      .limit(20)

    Turbo::StreamsChannel.broadcast_replace_to(
      "contact_#{contact.id}",
      target: ActionView::RecordIdentifier.dom_id(contact, :email_activity),
      partial: "contacts/email_activity",
      locals: { contact: contact, email_events: activity }
    )
  end

  private

  def set_default_status
    self.status ||= 'queued'
  end

  def broadcast_subscribed_views
    self.class.broadcast_subscribed_views_for(self)
  end
end
