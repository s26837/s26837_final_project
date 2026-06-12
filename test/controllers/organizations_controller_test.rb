require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user, password: "password123", password_confirmation: "password123")
    @organization = create(:organization, owner: @owner)
  end

  test "show requires authentication" do
    get organization_path(@organization)
    assert_redirected_to login_path
  end

  test "show renders for an owner" do
    sign_in(@owner)
    get organization_path(@organization)
    assert_response :success
  end

  test "update succeeds for admin" do
    sign_in(@owner)
    patch organization_path(@organization), params: { organization: { name: "Renamed" } }
    assert_redirected_to @organization
    assert_equal "Renamed", @organization.reload.name
  end

  test "update is blocked for non-admin member" do
    member = create(:user, password: "password123", password_confirmation: "password123")
    create(:organization_membership, user: member, organization: @organization, role: "member")
    sign_in(member)
    switch_to(@organization)

    patch organization_path(@organization), params: { organization: { name: "Hack" } }
    assert_not_equal "Hack", @organization.reload.name
  end

  test "leave forbids owner" do
    sign_in(@owner)
    delete leave_organization_path(@organization)
    assert_redirected_to @organization
    assert_match(/owner can't leave/, flash[:alert])
  end

  test "leave removes membership for non-owner" do
    member = create(:user, password: "password123", password_confirmation: "password123")
    create(:organization_membership, user: member, organization: @organization, role: "member")
    sign_in(member)

    assert_difference -> { OrganizationMembership.count }, -1 do
      delete leave_organization_path(@organization)
    end
    assert_redirected_to root_path
  end

  test "switch sets current organization" do
    second_org = create(:organization, owner: @owner)
    sign_in(@owner)
    post switch_organization_path(second_org)
    assert_redirected_to second_org
  end

  test "set_sendgrid_key with use_demo flips org into demo mode when ENV present" do
    sign_in(@owner)
    patch set_sendgrid_key_organization_path(@organization), params: { use_demo: "1" }
    assert @organization.reload.sendgrid_demo?
  end

  test "set_sendgrid_key with a key sets custom mode" do
    sign_in(@owner)
    patch set_sendgrid_key_organization_path(@organization), params: { sendgrid_api_key: "SG.MYKEY" }
    @organization.reload
    assert_equal "SG.MYKEY", @organization.sendgrid_api_key
    refute @organization.sendgrid_demo?
  end

  test "set_sendgrid_key with blank input redirects with alert" do
    sign_in(@owner)
    patch set_sendgrid_key_organization_path(@organization), params: { sendgrid_api_key: "" }
    assert_match(/No SendGrid key provided/, flash[:alert])
  end
end
