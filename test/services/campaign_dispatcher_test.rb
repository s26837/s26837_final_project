require "test_helper"

class CampaignDispatcherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @campaign = create(:campaign)
    @template = create(:email_template, organization: @campaign.organization)
    @step = @campaign.steps.create!(email_template: @template, position: 0, delay_hours: 0)
    @contact = create(:contact, organization: @campaign.organization)
  end

  test "dispatch transitions draft to sending and clears scheduled_at" do
    @campaign.update!(scheduled_at: 1.day.from_now, status: "scheduled")
    start = Time.utc(2026, 1, 1, 12, 0, 0)
    travel_to(start) do
      CampaignDispatcher.dispatch(@campaign, start_at: start)
    end
    @campaign.reload
    assert_equal "sending", @campaign.status
    assert_nil @campaign.scheduled_at
    assert_equal start.to_i, @campaign.sent_at.to_i
  end

  test "dispatch enqueues a CampaignSendJob for each step" do
    other = create(:email_template, organization: @campaign.organization)
    @campaign.steps.create!(email_template: other, position: 1, delay_hours: 24)

    assert_enqueued_jobs 2, only: CampaignSendJob do
      CampaignDispatcher.dispatch(@campaign)
    end
  end

  test "dispatch returns result with counts" do
    result = CampaignDispatcher.dispatch(@campaign)
    assert result.dispatched
    assert_equal 1, result.step_count
    assert_equal 1, result.contact_count
    assert_equal @campaign, result.campaign
  end

  test "dispatch does nothing for non-dispatchable statuses" do
    @campaign.update!(status: "sent")
    assert_no_enqueued_jobs only: CampaignSendJob do
      result = CampaignDispatcher.dispatch(@campaign)
      refute result.dispatched
      assert_equal 0, result.contact_count
      assert_equal 0, result.step_count
    end
  end

  test "Result#notice is friendly for single contact + single step" do
    result = CampaignDispatcher::Result.new(campaign: @campaign, contact_count: 1, step_count: 1, dispatched: true)
    assert_equal "Campaign is being sent to 1 contact", result.notice
  end

  test "Result#notice pluralises and includes step count" do
    result = CampaignDispatcher::Result.new(campaign: @campaign, contact_count: 3, step_count: 2, dispatched: true)
    assert_equal "Campaign is being sent to 3 contacts across 2 emails", result.notice
  end

  test "Result#notice is the cancellation message when not dispatched" do
    result = CampaignDispatcher::Result.new(campaign: @campaign, contact_count: 0, step_count: 0, dispatched: false)
    assert_match(/already being sent/, result.notice)
  end
end
