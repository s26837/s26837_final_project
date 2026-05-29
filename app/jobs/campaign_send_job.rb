class CampaignSendJob < ApplicationJob
  queue_as :default

  def perform(campaign_step_id, contact_ids)
    step = CampaignStep.find_by(id: campaign_step_id)
    return unless step

    campaign = step.campaign
    Contact.where(id: Array(contact_ids).uniq).find_each do |contact|
      next if step.campaign_sends.exists?(contact_id: contact.id)

      campaign_send = campaign.campaign_sends.create!(
        contact: contact,
        campaign_step: step,
        status: 'queued'
      )
      SendEmailJob.perform_later(campaign_send.id)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      next
    end
  end
end
