require "test_helper"

class CampaignSendTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:campaign_send).valid?
  end

  test "default status is queued" do
    send = build(:campaign_send, status: nil)
    send.save!
    assert_equal "queued", send.status
  end

  test "status must be in allowed set" do
    refute build(:campaign_send, status: "bogus").valid?
  end

  test "uniqueness of campaign_step+contact" do
    campaign = create(:campaign)
    template = create(:email_template, organization: campaign.organization)
    step = campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)
    contact = create(:contact, organization: campaign.organization)
    campaign.campaign_sends.create!(campaign_step: step, contact: contact)
    dup = campaign.campaign_sends.build(campaign_step: step, contact: contact)
    refute dup.valid?
  end

  test "mark_as_delivered! sets status and delivered_at" do
    send = create(:campaign_send)
    send.mark_as_delivered!
    assert_equal "delivered", send.status
    assert_not_nil send.delivered_at
  end

  test "mark_as_failed! sets status" do
    send = create(:campaign_send)
    send.mark_as_failed!
    assert_equal "failed", send.status
  end

  test "mark_as_bounced! sets status" do
    send = create(:campaign_send)
    send.mark_as_bounced!
    assert_equal "bounced", send.status
  end

  test "opened? reflects opened email event" do
    send = create(:campaign_send)
    refute send.opened?
    send.email_events.create!(event_type: "opened", occurred_at: Time.current)
    assert send.opened?
  end

  test "clicked? reflects clicked email event" do
    send = create(:campaign_send)
    refute send.clicked?
    send.email_events.create!(event_type: "clicked", occurred_at: Time.current)
    assert send.clicked?
  end

  test "queued and sent scopes" do
    queued = create(:campaign_send, status: "queued")
    sent = create(:campaign_send, status: "sent")
    assert_includes CampaignSend.queued, queued
    assert_includes CampaignSend.sent, sent
    refute_includes CampaignSend.queued, sent
  end
end
