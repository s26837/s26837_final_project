require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, password: "password123", password_confirmation: "password123")
    @organization = create(:organization, owner: @user)
    sign_in(@user)
  end

  test "requires authentication" do
    delete logout_path
    get organization_contacts_path(@organization)
    assert_redirected_to login_path
  end

  test "index renders for org member" do
    create(:contact, organization: @organization, email: "shown@example.com")
    get organization_contacts_path(@organization)
    assert_response :success
    assert_match "shown@example.com", response.body
  end

  test "index filters by tag_id" do
    tag = create(:tag, organization: @organization)
    tagged = create(:contact, organization: @organization, email: "tagged@example.com")
    create(:contact, organization: @organization, email: "untagged@example.com")
    tagged.tags << tag

    get organization_contacts_path(@organization, tag_id: tag.id)
    assert_response :success
    assert_match "tagged@example.com", response.body
    refute_match "untagged@example.com", response.body
  end

  test "create persists a valid contact" do
    assert_difference "Contact.count", 1 do
      post organization_contacts_path(@organization), params: {
        contact: { email: "new@example.com", first_name: "New", last_name: "Person" }
      }
    end
    assert_redirected_to organization_contacts_path(@organization)
  end

  test "create rejects an invalid contact" do
    assert_no_difference "Contact.count" do
      post organization_contacts_path(@organization), params: {
        contact: { email: "not-an-email" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "update modifies an existing contact" do
    contact = create(:contact, organization: @organization)
    patch organization_contact_path(@organization, contact), params: {
      contact: { first_name: "Renamed" }
    }
    assert_redirected_to organization_contact_path(@organization, contact)
    assert_equal "Renamed", contact.reload.first_name
  end

  test "destroy removes a contact" do
    contact = create(:contact, organization: @organization)
    assert_difference "Contact.count", -1 do
      delete organization_contact_path(@organization, contact)
    end
  end

  test "add_tag attaches a tag to the contact" do
    contact = create(:contact, organization: @organization)
    tag = create(:tag, organization: @organization)

    post add_tag_organization_contact_path(@organization, contact), params: { tag_id: tag.id }
    assert_includes contact.reload.tags, tag
  end

  test "remove_tag detaches a tag" do
    contact = create(:contact, organization: @organization)
    tag = create(:tag, organization: @organization)
    contact.tags << tag

    delete remove_tag_organization_contact_path(@organization, contact), params: { tag_id: tag.id }
    refute_includes contact.reload.tags, tag
  end

  test "bulk_destroy deletes contacts by tag" do
    tag = create(:tag, organization: @organization)
    target = create(:contact, organization: @organization)
    safe = create(:contact, organization: @organization)
    target.tags << tag

    assert_difference "Contact.count", -1 do
      delete bulk_destroy_organization_contacts_path(@organization), params: { tag_id: tag.id }
    end
    assert Contact.exists?(safe.id)
  end

  test "bulk_destroy without tag id reports error" do
    delete bulk_destroy_organization_contacts_path(@organization)
    assert_redirected_to organization_contacts_path(@organization)
    assert_match(/Please select a tag/, flash[:alert])
  end

  test "process_import requires a file" do
    post process_import_organization_contacts_path(@organization)
    assert_redirected_to import_organization_contacts_path(@organization)
    assert_match(/Please select a CSV file/, flash[:alert])
  end

  test "process_import imports a valid CSV" do
    file = Tempfile.new(["contacts", ".csv"])
    file.write("email,first_name,last_name\nintegration@example.com,Int,Test\n")
    file.rewind
    upload = Rack::Test::UploadedFile.new(file.path, "text/csv", original_filename: "contacts.csv")

    assert_difference "Contact.count", 1 do
      post process_import_organization_contacts_path(@organization), params: { csv_file: upload }
    end
    assert_redirected_to organization_contacts_path(@organization)
  end
end
