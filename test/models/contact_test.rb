require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:contact).valid?
  end

  test "requires email" do
    contact = build(:contact, email: nil)
    refute contact.valid?
  end

  test "email must be a valid format" do
    contact = build(:contact, email: "nope")
    refute contact.valid?
  end

  test "email is unique within an organization" do
    org = create(:organization)
    create(:contact, organization: org, email: "same@example.com")
    dup = build(:contact, organization: org, email: "same@example.com")
    refute dup.valid?
    assert_includes dup.errors[:email].join, "already exists"
  end

  test "same email allowed across different organizations" do
    org_a = create(:organization)
    org_b = create(:organization)
    create(:contact, organization: org_a, email: "shared@example.com")
    other = build(:contact, organization: org_b, email: "shared@example.com")
    assert other.valid?
  end

  test "normalize_email lowercases and strips before save" do
    org = create(:organization)
    contact = create(:contact, organization: org, email: "  UPPER@Example.COM ")
    assert_equal "upper@example.com", contact.email
  end

  test "full_name returns first and last name joined" do
    contact = build(:contact, first_name: "John", last_name: "Smith")
    assert_equal "John Smith", contact.full_name
  end

  test "full_name returns email when first and last name are blank" do
    contact = build(:contact, first_name: nil, last_name: nil, email: "alone@example.com")
    assert_equal "alone@example.com", contact.full_name
  end

  test "add_tags creates and assigns tags by name" do
    contact = create(:contact)
    contact.add_tags("vip", "newsletter")
    assert_equal ["vip", "newsletter"].sort, contact.tag_names.sort
    assert_equal 2, contact.organization.tags.count
  end

  test "add_tags reuses existing org tags" do
    org = create(:organization)
    create(:tag, organization: org, name: "vip")
    contact = create(:contact, organization: org)
    assert_no_difference "Tag.count" do
      contact.add_tags("vip")
    end
    assert_includes contact.tag_names, "vip"
  end

  test "add_tags is idempotent for the same tag" do
    contact = create(:contact)
    contact.add_tags("vip")
    contact.add_tags("vip")
    assert_equal 1, contact.tags.count
  end

  test "remove_tags removes only matching tag" do
    contact = create(:contact)
    contact.add_tags("vip", "newsletter")
    contact.remove_tags("vip")
    assert_equal ["newsletter"], contact.tag_names
  end

  test "with_tag scope returns contacts that have the tag" do
    org = create(:organization)
    tag = create(:tag, organization: org)
    a = create(:contact, organization: org)
    b = create(:contact, organization: org)
    a.tags << tag

    assert_includes org.contacts.with_tag(tag), a
    refute_includes org.contacts.with_tag(tag), b
  end

  test "search_by_name_or_email finds by partial match" do
    org = create(:organization)
    create(:contact, organization: org, email: "alice@example.com", first_name: "Alice", last_name: "Wonder")
    create(:contact, organization: org, email: "bob@example.com", first_name: "Bob", last_name: "Smith")

    results = org.contacts.search_by_name_or_email("alice")
    assert_equal 1, results.count
    assert_equal "alice@example.com", results.first.email
  end
end
