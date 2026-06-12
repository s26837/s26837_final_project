require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, password: "password123", password_confirmation: "password123")
  end

  test "new renders the login form" do
    get login_path
    assert_response :success
  end

  test "create signs in with valid credentials" do
    assert_difference -> { @user.sessions.count }, 1 do
      post login_path, params: { email: @user.email, password: "password123" }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "create rejects invalid credentials" do
    post login_path, params: { email: @user.email, password: "wrong-password" }
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash[:alert])
  end

  test "create rejects unknown email" do
    post login_path, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "destroy signs out current user" do
    sign_in(@user)
    assert_difference "Session.count", -1 do
      delete logout_path
    end
    assert_redirected_to root_path
  end
end
