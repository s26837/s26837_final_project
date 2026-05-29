class CampaignStep < ApplicationRecord
  belongs_to :campaign
  belongs_to :email_template
  has_many :campaign_sends, dependent: :destroy

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :delay_hours, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: :campaign_id }

  scope :ordered, -> { order(:position) }
end
