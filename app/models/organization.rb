class Organization < ApplicationRecord
  belongs_to :owner, class_name: 'User'

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :invitations, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :automation_rules, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :owner, presence: true

  after_create :add_owner_as_member

  def sendgrid_configured?
    sendgrid_demo? || sendgrid_api_key.present?
  end

  def sendgrid_mode
    return :demo   if sendgrid_demo?
    return :custom if sendgrid_api_key.present?
    :unconfigured
  end

  def effective_sendgrid_key
    return ENV["SENDGRID_DEMO_API_KEY"].presence if sendgrid_demo?
    sendgrid_api_key.presence
  end

  def admins
    users.joins(:organization_memberships)
         .where(organization_memberships: { organization_id: id, role: ['admin', 'owner'] })
  end

  def members
    users.joins(:organization_memberships)
         .where(organization_memberships: { organization_id: id })
  end

  private

  def add_owner_as_member
    organization_memberships.create!(user: owner, role: 'owner')
  end
end
