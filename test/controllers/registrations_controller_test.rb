require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the signup form" do
    get signup_path
    assert_response :success
  end

  test "create signs up a user and creates an organization" do
    assert_difference -> { User.count } => 1, -> { Organization.count } => 1 do
      post signup_path, params: {
        user: {
          name: "Sam",
          email: "sam@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path
    user = User.find_by(email: "sam@example.com")
    assert_equal "Sam's Organization", user.owned_organizations.first.name
  end

  test "create rejects mismatched password confirmation" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "Sam",
          email: "sam@example.com",
          password: "password123",
          password_confirmation: "different"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects duplicate email" do
    create(:user, email: "dup@example.com")
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "Other",
          email: "dup@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
