class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :owned_organizations, class_name: 'Organization', foreign_key: 'owner_id', dependent: :destroy
  has_many :campaigns, foreign_key: 'created_by', dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  normalizes :email, with: -> e { e.strip.downcase }

  def member_of?(organization)
    organization_memberships.exists?(organization: organization)
  end

  def role_in(organization)
    organization_memberships.find_by(organization: organization)&.role
  end

  def admin_of?(organization)
    membership = organization_memberships.find_by(organization: organization)
    membership&.role.in?(['admin', 'owner'])
  end

  def owner_of?(organization)
    owned_organizations.include?(organization)
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
