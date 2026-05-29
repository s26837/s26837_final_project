class Contact < ApplicationRecord
  belongs_to :organization
  has_many :contact_tags, dependent: :destroy
  has_many :tags, through: :contact_tags
  has_many :campaign_sends, dependent: :destroy
  has_many :campaigns, through: :campaign_sends
  has_many :automation_executions, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :organization_id, message: "already exists in this organization" }

  before_save :normalize_email

  scope :with_tag, ->(tag) { joins(:tags).where(tags: { id: tag.id }) }
  scope :with_any_tags, ->(tag_ids) { joins(:tags).where(tags: { id: tag_ids }).distinct }

  scope :search_by_email, ->(query) {
    where("email ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }
  scope :search_by_name_or_email, ->(query) {
    pattern = "%#{sanitize_sql_like(query)}%"
    where("email ILIKE :p OR first_name ILIKE :p OR last_name ILIKE :p", p: pattern)
  }

  def full_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def add_tags(*tag_names)
    tag_names.flatten.each do |tag_name|
      tag = organization.tags.find_or_create_by!(name: tag_name)
      tags << tag unless tags.include?(tag)
    end
  end

  def remove_tags(*tag_names)
    tag_names.flatten.each do |tag_name|
      tag = organization.tags.find_by(name: tag_name)
      tags.delete(tag) if tag
    end
  end

  def tag_names
    tags.pluck(:name)
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
