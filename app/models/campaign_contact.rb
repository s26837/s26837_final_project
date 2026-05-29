class CampaignContact < ApplicationRecord
  belongs_to :campaign
  belongs_to :contact

  validates :contact_id, uniqueness: { scope: :campaign_id }
end
