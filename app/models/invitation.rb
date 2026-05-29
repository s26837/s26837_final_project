class Invitation < ApplicationRecord
  belongs_to :organization

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :active,  -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def invite_url
    Rails.application.routes.url_helpers.show_invitation_url(token: token)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 1.week.from_now
  end
end
