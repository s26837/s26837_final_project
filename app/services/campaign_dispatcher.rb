class CampaignDispatcher
  DISPATCHABLE_STATUSES = %w[draft scheduled].freeze

  Result = Struct.new(:campaign, :contact_count, :step_count, :dispatched, keyword_init: true) do
    def notice
      return "Campaign is already being sent or has been sent. Nothing dispatched." unless dispatched

      contacts = "#{contact_count} contact#{'s' if contact_count != 1}"
      if step_count > 1
        "Campaign is being sent to #{contacts} across #{step_count} emails"
      else
        "Campaign is being sent to #{contacts}"
      end
    end
  end

  def self.dispatch(campaign, start_at: Time.current)
    new(campaign, start_at: start_at).dispatch
  end

  def initialize(campaign, start_at: Time.current)
    @campaign = campaign
    @start_at = start_at
  end

  def dispatch
    unless DISPATCHABLE_STATUSES.include?(@campaign.status)
      return Result.new(campaign: @campaign, contact_count: 0, step_count: 0, dispatched: false)
    end

    contact_ids = @campaign.target_contacts.pluck(:id).uniq
    @campaign.update!(status: 'sending', sent_at: @start_at, scheduled_at: nil)

    @campaign.steps.each do |step|
      send_at = @campaign.step_send_time(step, start_at: @start_at)
      CampaignSendJob.set(wait_until: send_at).perform_later(step.id, contact_ids)
    end

    Result.new(campaign: @campaign, contact_count: contact_ids.size, step_count: @campaign.steps.size, dispatched: true)
  end
end
