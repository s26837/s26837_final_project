class AutomationRule < ApplicationRecord
  belongs_to :organization
  belongs_to :email_template

  has_many :automation_executions, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :trigger_type, presence: true, inclusion: { in: %w[tag_based time_based] }
  validates :delay_hours, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :tag_based, -> { where(trigger_type: 'tag_based') }
  scope :time_based, -> { where(trigger_type: 'time_based') }

  def activate
    update(active: true)
  end

  def deactivate
    update(active: false)
  end

  def tag_based?
    trigger_type == 'tag_based'
  end

  def time_based?
    trigger_type == 'time_based'
  end

  def already_executed_for?(contact)
    automation_executions.exists?(contact: contact)
  end

  def dispatch_for!(contact, async: true)
    return nil if already_executed_for?(contact)

    campaign, step = ensure_automation_campaign
    campaign_send = nil

    ActiveRecord::Base.transaction do
      execution = automation_executions.create!(contact: contact, status: "pending")
      campaign_send = campaign.campaign_sends.create!(
        contact: contact, campaign_step: step, status: "queued"
      )
      execution.update!(
        campaign_send: campaign_send,
        executed_at: Time.current,
        status: "completed"
      )
    end

    if async
      SendEmailJob.perform_later(campaign_send.id)
    else
      SendEmailJob.perform_now(campaign_send.id)
    end

    campaign_send
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.info "Skipping duplicate dispatch for rule #{id}, contact #{contact.id}: #{e.message}"
    nil
  end

  private

  def ensure_automation_campaign
    name = "Automation: #{self.name}"
    campaign = organization.campaigns.find_by(name: name, status: "automated")
    campaign ||= organization.campaigns.create!(
      created_by: organization.owner_id,
      name: name,
      status: "automated",
      sent_at: Time.current
    )

    step = campaign.steps.ordered.first
    if step.nil?
      step = campaign.steps.create!(
        email_template: email_template,
        position: 0,
        delay_hours: 0
      )
    elsif step.email_template_id != email_template_id
      step.update!(email_template_id: email_template_id)
    end

    [campaign, step]
  end
end
