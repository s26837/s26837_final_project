require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, password: "password123", password_confirmation: "password123")
    @organization = create(:organization, owner: @user)
    sign_in(@user)
  end

  test "index lists tags" do
    create(:tag, organization: @organization, name: "shown")
    get organization_tags_path(@organization)
    assert_response :success
    assert_match "shown", response.body
  end

  test "create persists a tag" do
    assert_difference "Tag.count", 1 do
      post organization_tags_path(@organization), params: { tag: { name: "newtag", color: "#FF0000" } }
    end
  end

  test "destroy removes a tag" do
    tag = create(:tag, organization: @organization)
    assert_difference "Tag.count", -1 do
      delete organization_tag_path(@organization, tag)
    end
  end
end
