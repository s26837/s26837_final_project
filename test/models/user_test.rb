require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:user).valid?
  end

  test "requires email" do
    user = build(:user, email: nil)
    refute user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires name" do
    user = build(:user, name: nil)
    refute user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "email must be valid format" do
    user = build(:user, email: "not-an-email")
    refute user.valid?
    assert_includes user.errors[:email].join, "invalid"
  end

  test "email is unique case-insensitively" do
    create(:user, email: "duplicate@example.com")
    dup = build(:user, email: "DUPLICATE@example.com")
    refute dup.valid?
    assert_includes dup.errors[:email].join, "taken"
  end

  test "email is normalized on save" do
    user = create(:user, email: "  MiXeD@Example.COM  ")
    assert_equal "mixed@example.com", user.email
  end

  test "password must be at least 8 characters" do
    user = build(:user, password: "short", password_confirmation: "short")
    refute user.valid?
    assert_includes user.errors[:password].join, "too short"
  end

  test "has_secure_password authenticates correct password" do
    user = create(:user, password: "supersecret", password_confirmation: "supersecret")
    assert user.authenticate("supersecret")
    refute user.authenticate("nope")
  end

  test "owned_organizations returns organizations the user owns" do
    user = create(:user)
    owned = create(:organization, owner: user)
    other_owner = create(:user)
    create(:organization, owner: other_owner)
    assert_includes user.owned_organizations, owned
    assert_equal 1, user.owned_organizations.count
  end

  test "member_of? returns true when user has a membership" do
    user = create(:user)
    org = create(:organization, owner: user)
    assert user.member_of?(org)
  end

  test "member_of? returns false when no membership" do
    user = create(:user)
    other = create(:user)
    org = create(:organization, owner: other)
    refute user.member_of?(org)
  end

  test "role_in returns membership role" do
    user = create(:user)
    org = create(:organization, owner: user)
    assert_equal "owner", user.role_in(org)
  end

  test "admin_of? returns true for admin and owner roles" do
    owner = create(:user)
    admin = create(:user)
    member = create(:user)
    org = create(:organization, owner: owner)
    create(:organization_membership, user: admin, organization: org, role: "admin")
    create(:organization_membership, user: member, organization: org, role: "member")

    assert owner.admin_of?(org)
    assert admin.admin_of?(org)
    refute member.admin_of?(org)
  end

  test "owner_of? returns true only for owner" do
    owner = create(:user)
    other = create(:user)
    org = create(:organization, owner: owner)
    create(:organization_membership, user: other, organization: org, role: "admin")

    assert owner.owner_of?(org)
    refute other.owner_of?(org)
  end

  test "destroys sessions when user is destroyed" do
    user = create(:user)
    user.sessions.create!
    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
