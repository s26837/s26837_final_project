require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:organization).valid?
  end

  test "requires name" do
    org = build(:organization, name: nil)
    refute org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "name minimum length" do
    org = build(:organization, name: "a")
    refute org.valid?
    assert_includes org.errors[:name].join, "too short"
  end

  test "name maximum length" do
    org = build(:organization, name: "x" * 101)
    refute org.valid?
    assert_includes org.errors[:name].join, "too long"
  end

  test "after_create adds owner as member with owner role" do
    user = create(:user)
    org = create(:organization, owner: user)
    membership = org.organization_memberships.find_by(user: user)
    assert_equal "owner", membership.role
  end

  test "sendgrid_configured? false when neither demo nor key present" do
    org = create(:organization)
    refute org.sendgrid_configured?
  end

  test "sendgrid_configured? true with demo flag" do
    org = create(:organization, :with_demo_sendgrid)
    assert org.sendgrid_configured?
  end

  test "sendgrid_configured? true with custom key" do
    org = create(:organization, :with_custom_sendgrid)
    assert org.sendgrid_configured?
  end

  test "sendgrid_mode returns :unconfigured when no config" do
    assert_equal :unconfigured, create(:organization).sendgrid_mode
  end

  test "sendgrid_mode returns :demo when demo enabled" do
    assert_equal :demo, create(:organization, :with_demo_sendgrid).sendgrid_mode
  end

  test "sendgrid_mode returns :custom when custom key present" do
    assert_equal :custom, create(:organization, :with_custom_sendgrid).sendgrid_mode
  end

  test "effective_sendgrid_key returns ENV value in demo mode" do
    org = create(:organization, :with_demo_sendgrid)
    original = ENV["SENDGRID_DEMO_API_KEY"]
    ENV["SENDGRID_DEMO_API_KEY"] = "demo-key-value"
    assert_equal "demo-key-value", org.effective_sendgrid_key
  ensure
    ENV["SENDGRID_DEMO_API_KEY"] = original
  end

  test "effective_sendgrid_key returns custom key when set" do
    org = create(:organization, :with_custom_sendgrid)
    assert_equal "SG.custom-test-key", org.effective_sendgrid_key
  end

  test "admins scope returns owners and admins" do
    owner = create(:user)
    admin = create(:user)
    member = create(:user)
    org = create(:organization, owner: owner)
    create(:organization_membership, user: admin, organization: org, role: "admin")
    create(:organization_membership, user: member, organization: org, role: "member")

    assert_includes org.admins, owner
    assert_includes org.admins, admin
    refute_includes org.admins, member
  end

  test "members scope returns all org members" do
    owner = create(:user)
    member = create(:user)
    org = create(:organization, owner: owner)
    create(:organization_membership, user: member, organization: org, role: "member")

    assert_equal 2, org.members.count
  end

  test "destroying organization destroys memberships and contacts" do
    org = create(:organization)
    create(:contact, organization: org)
    assert_difference -> { OrganizationMembership.count } => -1, -> { Contact.count } => -1 do
      org.destroy
    end
  end
end
