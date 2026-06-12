require "test_helper"

class EmailEventTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:email_event).valid?
  end

  test "requires event_type and occurred_at" do
    event = build(:email_event, event_type: nil, occurred_at: nil)
    refute event.valid?
    assert_includes event.errors[:event_type], "can't be blank"
    assert_includes event.errors[:occurred_at], "can't be blank"
  end

  test "event_type must be in allowed set" do
    refute build(:email_event, event_type: "exploded").valid?
  end

  test "contact returns the contact of the campaign_send" do
    send = create(:campaign_send)
    event = create(:email_event, campaign_send: send)
    assert_equal send.contact, event.contact
  end

  test "opened/clicked/delivered/bounced scopes" do
    send = create(:campaign_send)
    opened = create(:email_event, campaign_send: send, event_type: "opened")
    clicked = create(:email_event, campaign_send: send, event_type: "clicked")
    delivered = create(:email_event, campaign_send: send, event_type: "delivered")
    bounced = create(:email_event, campaign_send: send, event_type: "bounced")

    assert_includes EmailEvent.opened, opened
    assert_includes EmailEvent.clicked, clicked
    assert_includes EmailEvent.delivered, delivered
    assert_includes EmailEvent.bounced, bounced
  end
end
