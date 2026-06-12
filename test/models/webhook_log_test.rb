require "test_helper"

class WebhookLogTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:webhook_log).valid?
  end

  test "requires event_type and payload" do
    log = build(:webhook_log, event_type: nil, payload: nil)
    refute log.valid?
    assert_includes log.errors[:event_type], "can't be blank"
    assert_includes log.errors[:payload], "can't be blank"
  end

  test "unprocessed and processed scopes" do
    a = create(:webhook_log, processed: false)
    b = create(:webhook_log, processed: true)
    assert_includes WebhookLog.unprocessed, a
    assert_includes WebhookLog.processed, b
    refute_includes WebhookLog.unprocessed, b
  end

  test "by_event_type filters by event_type" do
    delivered = create(:webhook_log, event_type: "delivered")
    bounced = create(:webhook_log, event_type: "bounce")
    assert_includes WebhookLog.by_event_type("delivered"), delivered
    refute_includes WebhookLog.by_event_type("delivered"), bounced
  end

  test "process! attaches an email_event when matching campaign_send exists" do
    send = create(:campaign_send, sendgrid_message_id: "sg-msg-1")
    log = create(:webhook_log,
      event_type: "opened",
      payload: { "event" => "opened", "sg_message_id" => "sg-msg-1", "timestamp" => Time.current.to_i, "ip" => "1.2.3.4" }
    )

    assert_difference "EmailEvent.count", 1 do
      log.process!
    end
    assert log.reload.processed?
    event = send.email_events.first
    assert_equal "opened", event.event_type
    assert_equal "1.2.3.4", event.ip_address
  end

  test "process! marks delivered campaign_send as delivered" do
    send = create(:campaign_send, sendgrid_message_id: "sg-msg-2", status: "sent")
    log = create(:webhook_log,
      event_type: "delivered",
      payload: { "event" => "delivered", "sg_message_id" => "sg-msg-2", "timestamp" => Time.current.to_i }
    )
    log.process!
    assert_equal "delivered", send.reload.status
    assert_not_nil send.delivered_at
  end

  test "process! marks bounced for bounce event" do
    send = create(:campaign_send, sendgrid_message_id: "sg-msg-3", status: "sent")
    log = create(:webhook_log,
      event_type: "bounce",
      payload: { "event" => "bounce", "sg_message_id" => "sg-msg-3", "timestamp" => Time.current.to_i }
    )
    log.process!
    assert_equal "bounced", send.reload.status
  end

  test "process! is idempotent (no-op if processed)" do
    log = create(:webhook_log, processed: true)
    assert_no_difference "EmailEvent.count" do
      log.process!
    end
  end

  test "process! does not raise when no matching campaign_send" do
    log = create(:webhook_log,
      payload: { "event" => "delivered", "sg_message_id" => "nope", "timestamp" => Time.current.to_i }
    )
    assert_nothing_raised { log.process! }
    assert log.reload.processed?
  end
end
