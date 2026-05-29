class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :user, presence: true
  validates :organization, presence: true
  validates :role, presence: true, inclusion: { in: %w[owner admin member] }
  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }

  scope :admins, -> { where(role: ['admin', 'owner']) }
  scope :members, -> { where(role: 'member') }
  scope :owners, -> { where(role: 'owner') }

  def owner?
    role == 'owner'
  end

  def admin?
    role.in?(['admin', 'owner'])
  end

  def member?
    role == 'member'
  end

  def promote_to_admin!
    return false if owner?
    update(role: 'admin')
  end

  def demote_to_member!
    return false if owner?
    update(role: 'member')
  end
end
