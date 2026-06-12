require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "sendgrid endpoint accepts a single event payload" do
    assert_difference "WebhookLog.count", 1 do
      assert_enqueued_jobs 1, only: ProcessSendgridEventJob do
        post webhooks_sendgrid_path,
             params: { event: "delivered", sg_message_id: "msg-x", timestamp: Time.current.to_i }
      end
    end
    assert_response :ok
  end

  test "sendgrid endpoint accepts an array of events" do
    payload = [
      { event: "delivered", sg_message_id: "msg-1", timestamp: Time.current.to_i },
      { event: "opened",    sg_message_id: "msg-2", timestamp: Time.current.to_i }
    ]
    assert_difference "WebhookLog.count", 2 do
      post webhooks_sendgrid_path, params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    end
    assert_response :ok
  end
end
