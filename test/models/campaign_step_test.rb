require "test_helper"

class CampaignStepTest < ActiveSupport::TestCase
  test "valid factory" do
    step = build(:campaign_step)
    assert step.valid?, step.errors.full_messages.join(", ")
  end

  test "requires position and delay_hours" do
    step = build(:campaign_step, position: nil, delay_hours: nil)
    refute step.valid?
    assert_includes step.errors[:position], "can't be blank"
    assert_includes step.errors[:delay_hours], "can't be blank"
  end

  test "position must be an integer >= 0" do
    refute build(:campaign_step, position: -1).valid?
    refute build(:campaign_step, position: 1.5).valid?
  end

  test "delay_hours must be an integer >= 0" do
    refute build(:campaign_step, delay_hours: -2).valid?
  end

  test "position is unique within campaign" do
    campaign = create(:campaign)
    template = create(:email_template, organization: campaign.organization)
    campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)
    dup = campaign.steps.build(email_template: template, position: 0, delay_hours: 0)
    refute dup.valid?
  end

  test "ordered scope orders by position ascending" do
    campaign = create(:campaign)
    template = create(:email_template, organization: campaign.organization)
    s2 = campaign.steps.create!(email_template: template, position: 1, delay_hours: 0)
    s1 = campaign.steps.create!(email_template: template, position: 0, delay_hours: 0)
    assert_equal [s1, s2], campaign.steps.ordered.to_a
  end
end
