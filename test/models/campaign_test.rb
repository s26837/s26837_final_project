require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:campaign).valid?
  end

  test "requires name" do
    campaign = build(:campaign, name: nil)
    refute campaign.valid?
  end

  test "name length boundaries" do
    refute build(:campaign, name: "a").valid?
    refute build(:campaign, name: "a" * 201).valid?
  end

  test "default status is draft when created without one" do
    campaign = build(:campaign, status: nil)
    campaign.save!
    assert_equal "draft", campaign.status
  end

  test "status must be a known value" do
    campaign = build(:campaign, status: "weird")
    refute campaign.valid?
  end

  test "scheduled_at must be in the future when scheduled" do
    campaign = build(:campaign, status: "scheduled", scheduled_at: 1.hour.ago)
    refute campaign.valid?
    assert_includes campaign.errors[:scheduled_at].join, "future"
  end

  test "scheduled_at in past is OK for non-scheduled status" do
    campaign = build(:campaign, status: "draft", scheduled_at: 1.hour.ago)
    assert campaign.valid?
  end

  test "predicates reflect status" do
    assert build(:campaign, status: "draft").draft?
    assert build(:campaign, status: "scheduled").scheduled?
    assert build(:campaign, status: "sent").sent?
  end

  test "draft scope" do
    a = create(:campaign, status: "draft")
    create(:campaign, status: "sent")
    assert_includes Campaign.draft, a
    assert_equal 1, Campaign.draft.count
  end

  test "ready_to_send? requires steps and not sent" do
    campaign = create(:campaign)
    refute campaign.ready_to_send?

    template = create(:email_template, organization: campaign.organization)
    campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)
    assert campaign.reload.ready_to_send?

    campaign.update!(status: "sent")
    refute campaign.ready_to_send?
  end

  test "step_send_time accumulates delays" do
    campaign = create(:campaign)
    t1 = create(:email_template, organization: campaign.organization)
    t2 = create(:email_template, organization: campaign.organization)
    s1 = campaign.steps.create!(email_template: t1, position: 0, delay_hours: 0)
    s2 = campaign.steps.create!(email_template: t2, position: 1, delay_hours: 24)

    start = Time.utc(2026, 1, 1, 12, 0, 0)
    assert_equal start, campaign.step_send_time(s1, start_at: start)
    assert_equal start + 24.hours, campaign.step_send_time(s2, start_at: start)
  end

  test "target_contacts returns all org contacts when no tags or explicit contacts" do
    campaign = create(:campaign)
    contact = create(:contact, organization: campaign.organization)
    assert_includes campaign.target_contacts, contact
  end

  test "target_contacts returns only tagged contacts when tag filter applied" do
    campaign = create(:campaign)
    tag = create(:tag, organization: campaign.organization)
    tagged = create(:contact, organization: campaign.organization)
    other = create(:contact, organization: campaign.organization)
    tagged.tags << tag
    campaign.tags << tag

    targets = campaign.target_contacts
    assert_includes targets, tagged
    refute_includes targets, other
  end

  test "target_contacts unions explicit contacts with tag contacts" do
    campaign = create(:campaign)
    tag = create(:tag, organization: campaign.organization)
    tagged = create(:contact, organization: campaign.organization)
    explicit = create(:contact, organization: campaign.organization)
    tagged.tags << tag
    campaign.tags << tag
    campaign.campaign_contacts.create!(contact: explicit)

    ids = campaign.target_contacts.pluck(:id)
    assert_includes ids, tagged.id
    assert_includes ids, explicit.id
  end

  test "stats returns zeros for fresh campaign" do
    campaign = create(:campaign)
    template = create(:email_template, organization: campaign.organization)
    campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)

    assert_equal 0, campaign.total_sends
    assert_equal 0, campaign.delivered_count
    assert_equal 0, campaign.opened_count
    assert_equal 0, campaign.clicked_count
    assert_equal 0, campaign.delivery_rate
    assert_equal 0, campaign.open_rate
    assert_equal 0, campaign.click_rate
  end

  test "stats include sent campaign_sends and events" do
    campaign = create(:campaign)
    template = create(:email_template, organization: campaign.organization)
    step = campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)
    contact = create(:contact, organization: campaign.organization)
    send = campaign.campaign_sends.create!(campaign_step: step, contact: contact, status: "delivered")
    send.email_events.create!(event_type: "opened", occurred_at: Time.current)

    campaign.reload_stats
    assert_equal 1, campaign.total_sends
    assert_equal 1, campaign.delivered_count
    assert_equal 1, campaign.opened_count
    assert_equal 100.0, campaign.delivery_rate
    assert_equal 100.0, campaign.open_rate
  end
end
