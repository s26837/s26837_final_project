require "test_helper"
require "tempfile"

class ContactImporterTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
  end

  def csv_file(contents)
    file = Tempfile.new(["contacts", ".csv"])
    file.write(contents)
    file.rewind
    file
  end

  test "imports rows from CSV" do
    file = csv_file(<<~CSV)
      email,first_name,last_name
      alice@example.com,Alice,Wonder
      bob@example.com,Bob,Smith
    CSV

    result = ContactImporter.call(organization: @organization, file: file)
    assert result.success?
    assert_equal 2, result.imported_count
    assert_equal 2, @organization.contacts.count
  end

  test "tags imported contacts when tag_name provided" do
    file = csv_file(<<~CSV)
      email,first_name,last_name
      tagged@example.com,Tagged,User
    CSV

    result = ContactImporter.call(organization: @organization, file: file, tag_name: "newsletter")
    assert result.success?
    contact = @organization.contacts.find_by(email: "tagged@example.com")
    assert_includes contact.tag_names, "newsletter"
  end

  test "collects errors for invalid rows but keeps the valid ones" do
    file = csv_file(<<~CSV)
      email,first_name,last_name
      good@example.com,Good,User
      not-an-email,Bad,User
    CSV

    result = ContactImporter.call(organization: @organization, file: file)
    refute result.success?
    assert_equal 1, result.imported_count
    assert(result.errors.any? { |e| e.include?("not-an-email") })
  end

  test "duplicate row in same org reports an error" do
    create(:contact, organization: @organization, email: "dup@example.com")
    file = csv_file(<<~CSV)
      email,first_name,last_name
      dup@example.com,Dup,User
    CSV

    result = ContactImporter.call(organization: @organization, file: file)
    refute result.success?
    assert_equal 0, result.imported_count
    assert(result.errors.any? { |e| e.include?("dup@example.com") })
  end

  test "Result#success? false when errors present" do
    result = ContactImporter::Result.new(imported_count: 0, errors: ["boom"])
    refute result.success?
  end

  test "Result#success? true when errors empty" do
    result = ContactImporter::Result.new(imported_count: 5, errors: [])
    assert result.success?
  end
end
