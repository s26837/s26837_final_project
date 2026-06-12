require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:tag).valid?
  end

  test "requires name" do
    tag = build(:tag, name: nil)
    refute tag.valid?
  end

  test "name uniqueness within organization" do
    org = create(:organization)
    create(:tag, organization: org, name: "vip")
    dup = build(:tag, organization: org, name: "vip")
    refute dup.valid?
    assert_includes dup.errors[:name].join, "already exists"
  end

  test "same name allowed across organizations" do
    create(:tag, name: "vip", organization: create(:organization))
    other = build(:tag, name: "vip", organization: create(:organization))
    assert other.valid?
  end

  test "name is normalized to lower-case and stripped" do
    tag = create(:tag, name: "  VIP Member  ")
    assert_equal "vip member", tag.name
  end

  test "name length boundaries" do
    refute build(:tag, name: "").valid?
    refute build(:tag, name: "x" * 51).valid?
    assert build(:tag, name: "x" * 50).valid?
  end

  test "color must be hex format if present" do
    refute build(:tag, color: "red").valid?
    assert build(:tag, color: "#FF00AA").valid?
    assert build(:tag, color: nil).valid?
  end

  test "display_color falls back to default when blank" do
    tag = build(:tag, color: nil)
    assert_equal "#6B7280", tag.display_color
  end

  test "display_color returns set color" do
    tag = build(:tag, color: "#123ABC")
    assert_equal "#123ABC", tag.display_color
  end

  test "contacts_count returns linked contacts count" do
    tag = create(:tag)
    contact = create(:contact, organization: tag.organization)
    contact.tags << tag
    assert_equal 1, tag.contacts_count
  end
end
