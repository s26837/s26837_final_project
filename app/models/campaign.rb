class Campaign < ApplicationRecord
  belongs_to :organization
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by'

  has_many :steps, -> { order(:position) }, class_name: 'CampaignStep', dependent: :destroy, inverse_of: :campaign
  has_many :step_templates, through: :steps, source: :email_template
  has_many :campaign_tags, dependent: :destroy
  has_many :tags, through: :campaign_tags
  has_many :campaign_contacts, dependent: :destroy
  has_many :targeted_contacts, through: :campaign_contacts, source: :contact
  has_many :campaign_sends, dependent: :destroy
  has_many :contacts, through: :campaign_sends

  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :status, presence: true, inclusion: { in: %w[draft scheduled sending sent cancelled automated] }
  validate :scheduled_at_in_future, if: -> { scheduled_at.present? && status == 'scheduled' }

  before_validation :set_default_status, on: :create

  scope :draft, -> { where(status: 'draft') }
  scope :scheduled, -> { where(status: 'scheduled') }
  scope :sent, -> { where(status: 'sent') }
  scope :recent, -> { order(created_at: :desc) }

  def stats
    @stats ||= begin
      active_sends = campaign_sends.where.not(campaign_step_id: nil)

      sends = active_sends.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE status IN ('sent', 'delivered'))")
      ) || [0, 0]

      events = EmailEvent.where(campaign_send_id: active_sends.select(:id)).pick(
        Arel.sql("COUNT(DISTINCT CASE WHEN event_type = 'opened'  THEN campaign_send_id END)"),
        Arel.sql("COUNT(DISTINCT CASE WHEN event_type = 'clicked' THEN campaign_send_id END)")
      ) || [0, 0]

      {
        total_sent: sends[0].to_i,
        delivered:  sends[1].to_i,
        opened:     events[0].to_i,
        clicked:    events[1].to_i
      }
    end
  end

  def reload_stats
    @stats = nil
    stats
  end

  def total_sends;     stats[:total_sent]; end
  def delivered_count; stats[:delivered];  end
  def opened_count;    stats[:opened];     end
  def clicked_count;   stats[:clicked];    end

  def delivery_rate
    return 0 if total_sends.zero?
    (delivered_count.to_f / total_sends * 100).round(2)
  end

  def open_rate
    return 0 if delivered_count.zero?
    (opened_count.to_f / delivered_count * 100).round(2)
  end

  def click_rate
    return 0 if delivered_count.zero?
    (clicked_count.to_f / delivered_count * 100).round(2)
  end

  def ready_to_send?
    steps.any? && !sent?
  end

  def step_send_time(step, start_at: Time.current)
    cumulative = 0
    steps.each do |s|
      cumulative += s.delay_hours.to_i
      return start_at + cumulative.hours if s.id == step.id
    end
    start_at
  end

  def sent?
    status == 'sent'
  end

  def draft?
    status == 'draft'
  end

  def scheduled?
    status == 'scheduled'
  end

  def target_contacts
    explicit_ids = campaign_contacts.pluck(:contact_id)
    tag_ids      = campaign_tags.pluck(:tag_id)

    if explicit_ids.empty? && tag_ids.empty?
      organization.contacts
    else
      tag_match_ids = if tag_ids.any?
        organization.contacts.joins(:contact_tags).where(contact_tags: { tag_id: tag_ids }).distinct.pluck(:id)
      else
        []
      end
      union_ids = (tag_match_ids + explicit_ids).uniq
      organization.contacts.where(id: union_ids)
    end
  end

  private

  def set_default_status
    self.status ||= 'draft'
  end

  def scheduled_at_in_future
    errors.add(:scheduled_at, "must be in the future") if scheduled_at <= Time.current
  end
end
