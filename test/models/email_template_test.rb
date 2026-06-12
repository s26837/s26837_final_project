require "test_helper"

class EmailTemplateTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:email_template).valid?
  end

  test "requires name, subject, html_content" do
    template = build(:email_template, name: nil, subject: nil, html_content: nil)
    refute template.valid?
    assert_includes template.errors[:name], "can't be blank"
    assert_includes template.errors[:subject], "can't be blank"
    assert_includes template.errors[:html_content], "can't be blank"
  end

  test "name length boundaries" do
    refute build(:email_template, name: "a").valid?
    refute build(:email_template, name: "a" * 101).valid?
    assert build(:email_template, name: "a" * 100).valid?
  end

  test "duplicate copies template with new name" do
    template = create(:email_template, name: "Welcome")
    copy = template.duplicate
    assert_equal "Welcome (Copy)", copy.name
    assert_equal template.subject, copy.subject
    assert copy.new_record?
  end

  test "blocks_array returns empty array when blocks blank" do
    template = build(:email_template, blocks: nil)
    assert_equal [], template.blocks_array
  end

  test "blocks_array converts entries to indifferent access" do
    template = create(:email_template, :with_blocks)
    assert template.blocks_array.first.is_a?(ActiveSupport::HashWithIndifferentAccess)
  end

  test "before_validation renders html_content from blocks when present" do
    template = build(:email_template, blocks: [{ "type" => "heading", "level" => 1, "text" => "Hi" }], html_content: nil)
    template.valid?
    assert_includes template.html_content, "<h1"
    assert_includes template.html_content, "Hi"
  end

  test "block renderer escapes user content" do
    template = create(:email_template,
      blocks: [{ "type" => "paragraph", "text" => "<script>alert(1)</script>" }],
      html_content: nil
    )
    refute_includes template.html_content, "<script>alert(1)</script>"
    assert_includes template.html_content, "&lt;script&gt;"
  end

  test "block renderer sanitizes button color and url" do
    template = create(:email_template,
      blocks: [{ "type" => "button", "label" => "Go", "url" => "javascript:alert(1)", "color" => "javascript:" }],
      html_content: nil
    )
    refute_includes template.html_content, "javascript:"
    assert_includes template.html_content, "#4F46E5"
  end

  test "block renderer prefixes bare host with https" do
    template = create(:email_template,
      blocks: [{ "type" => "link", "text" => "Visit", "url" => "example.com" }],
      html_content: nil
    )
    assert_includes template.html_content, "https://example.com"
  end

  test "spacer renders height based on size" do
    template = create(:email_template,
      blocks: [{ "type" => "spacer", "size" => "large" }],
      html_content: nil
    )
    assert_includes template.html_content, "48px"
  end
end
