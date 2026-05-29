class AutomationExecution < ApplicationRecord
  belongs_to :automation_rule
  belongs_to :contact
  belongs_to :campaign_send, optional: true

  validates :status, presence: true, inclusion: { in: %w[pending executing completed failed] }
  validates :automation_rule_id, uniqueness: { scope: :contact_id }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  def execute!
    return unless pending?

    update!(status: 'executing')

    begin
      update!(
        status: 'completed',
        executed_at: Time.current
      )
    rescue => e
      update!(
        status: 'failed',
        error_message: e.message
      )
    end
  end

  def pending?
    status == 'pending'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def ready_to_execute?
    pending? && created_at <= Time.current - automation_rule.delay_hours.hours
  end
end
