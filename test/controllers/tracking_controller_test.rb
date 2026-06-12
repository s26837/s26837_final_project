require "test_helper"

class TrackingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @send = create(:campaign_send)
  end

  test "open creates an opened email event and returns a gif" do
    assert_difference "EmailEvent.count", 1 do
      get track_open_path(campaign_send_id: @send.id)
    end
    event = @send.email_events.last
    assert_equal "opened", event.event_type
    assert_response :success
    assert_equal "image/gif", response.media_type
  end

  test "open returns gif even for unknown send" do
    assert_no_difference "EmailEvent.count" do
      get track_open_path(campaign_send_id: 0)
    end
    assert_response :success
  end

  test "click logs event and redirects to safe url" do
    target = "https://example.com/welcome"
    assert_difference "EmailEvent.count", 1 do
      get track_click_path(campaign_send_id: @send.id, url: target)
    end
    assert_redirected_to target
    event = @send.email_events.last
    assert_equal "clicked", event.event_type
    assert_equal target, event.url
  end

  test "click redirects to root when url is unsafe" do
    assert_no_difference "EmailEvent.count" do
      get track_click_path(campaign_send_id: @send.id, url: "javascript:alert(1)")
    end
    assert_redirected_to root_path
  end

  test "click redirects to root when url is blank" do
    get track_click_path(campaign_send_id: @send.id)
    assert_redirected_to root_path
  end
end
