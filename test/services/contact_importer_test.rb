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

  test "skips rows missing mandatory columns without erroring" do
    file = csv_file(<<~CSV)
      email,first_name,last_name
      complete@example.com,Complete,User
      noname@example.com,,
      ,Nobody,Here
    CSV

    result = ContactImporter.call(organization: @organization, file: file)
    assert result.success?
    assert_equal 1, result.imported_count
    assert_equal 2, result.skipped_count
    assert_equal 1, @organization.contacts.count
  end

  test "imports files with mixed CRLF and LF line endings" do
    file = csv_file(
      "email, first_name, last_name\r\n" \
      "a@example.com, Ann, One\n" \
      "b@example.com, Bo, Two\r\n"
    )

    result = ContactImporter.call(organization: @organization, file: file)
    assert result.success?, result.errors.inspect
    assert_equal 2, result.imported_count
  end

  test "returns an error instead of raising on an unreadable CSV" do
    file = csv_file(%(email,first_name,last_name\n"unterminated, Bad, Row\n))

    result = ContactImporter.call(organization: @organization, file: file)
    refute result.success?
    assert_equal 0, result.imported_count
    assert(result.errors.any? { |e| e.include?("Could not read the file as CSV") })
  end

  test "reuses an existing tag regardless of name capitalization" do
    create(:contact, organization: @organization, email: "existing@example.com")
        .add_tags("Piritas")

    file = csv_file(<<~CSV)
      email,first_name,last_name
      fresh@example.com,Fresh,User
    CSV

    result = ContactImporter.call(organization: @organization, file: file, tag_name: "PIRITAS")
    assert result.success?, result.errors.inspect
    assert_equal 1, result.imported_count
    assert_equal 1, @organization.tags.where(name: "piritas").count
    assert_includes @organization.contacts.find_by(email: "fresh@example.com").tag_names, "piritas"
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
