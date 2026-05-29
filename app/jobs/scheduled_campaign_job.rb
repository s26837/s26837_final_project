class ScheduledCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign_id, scheduled_at_epoch)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign
    return unless campaign.status == 'scheduled'
    return unless campaign.scheduled_at&.to_i == scheduled_at_epoch

    CampaignDispatcher.dispatch(campaign)
  end
end
