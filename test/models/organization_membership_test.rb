require "test_helper"

class OrganizationMembershipTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:organization_membership).valid?
  end

  test "role must be one of owner, admin, member" do
    membership = build(:organization_membership, role: "intern")
    refute membership.valid?
    assert_includes membership.errors[:role].join, "is not included"
  end

  test "uniqueness scoped to organization" do
    user = create(:user)
    org = create(:organization)
    create(:organization_membership, user: user, organization: org, role: "member")
    dup = build(:organization_membership, user: user, organization: org, role: "admin")
    refute dup.valid?
    assert_includes dup.errors[:user_id].join, "already a member"
  end

  test "owner? admin? member? predicates" do
    owner = build(:organization_membership, role: "owner")
    admin = build(:organization_membership, role: "admin")
    member = build(:organization_membership, role: "member")

    assert owner.owner?
    assert owner.admin?
    refute owner.member?

    refute admin.owner?
    assert admin.admin?
    refute admin.member?

    refute member.owner?
    refute member.admin?
    assert member.member?
  end

  test "promote_to_admin! updates a member to admin" do
    membership = create(:organization_membership, role: "member")
    assert membership.promote_to_admin!
    assert_equal "admin", membership.reload.role
  end

  test "promote_to_admin! refuses to demote an owner" do
    user = create(:user)
    org = create(:organization, owner: user)
    membership = org.organization_memberships.find_by(user: user)
    refute membership.promote_to_admin!
    assert_equal "owner", membership.reload.role
  end

  test "demote_to_member! demotes an admin" do
    membership = create(:organization_membership, role: "admin")
    assert membership.demote_to_member!
    assert_equal "member", membership.reload.role
  end

  test "demote_to_member! refuses to demote an owner" do
    user = create(:user)
    org = create(:organization, owner: user)
    membership = org.organization_memberships.find_by(user: user)
    refute membership.demote_to_member!
    assert_equal "owner", membership.reload.role
  end

  test "admins scope returns admins and owners" do
    org = create(:organization)
    create(:organization_membership, organization: org, role: "admin")
    create(:organization_membership, organization: org, role: "member")
    assert_equal 2, org.organization_memberships.admins.count
  end
end
