class Tag < ApplicationRecord
  belongs_to :organization
  has_many :contact_tags, dependent: :destroy
  has_many :contacts, through: :contact_tags
  has_many :campaign_tags, dependent: :destroy
  has_many :campaigns, through: :campaign_tags

  validates :name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :name, uniqueness: { scope: :organization_id, message: "already exists in this organization" }
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i, allow_blank: true }


  before_validation :normalize_name

  scope :by_name, -> { order(:name) }

  def self.normalize_name(value)
    value.to_s.strip.downcase
  end

  def contacts_count
    contacts.count
  end

  def display_color
    color.presence || '#6B7280'
  end

  private

  def normalize_name
    self.name = self.class.normalize_name(name) if name.present?
  end
end
