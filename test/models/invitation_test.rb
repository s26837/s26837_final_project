require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:invitation).valid?
  end

  test "token is generated on create" do
    inv = create(:invitation)
    assert inv.token.present?
    assert inv.token.length > 20
  end

  test "expires_at is set to a week from now" do
    inv = create(:invitation)
    assert inv.expires_at > Time.current
    assert_in_delta 1.week.from_now.to_i, inv.expires_at.to_i, 5
  end

  test "expired? when expires_at is past" do
    inv = create(:invitation)
    inv.update_column(:expires_at, 1.hour.ago)
    assert inv.expired?
  end

  test "not expired when expires_at is future" do
    inv = create(:invitation)
    refute inv.expired?
  end

  test "active scope only returns non-expired invitations" do
    fresh = create(:invitation)
    stale = create(:invitation)
    stale.update_column(:expires_at, 1.hour.ago)

    assert_includes Invitation.active, fresh
    refute_includes Invitation.active, stale
    assert_includes Invitation.expired, stale
  end

  test "token uniqueness" do
    inv = create(:invitation)
    dup = build(:invitation, token: inv.token)
    refute dup.valid?
  end
end
