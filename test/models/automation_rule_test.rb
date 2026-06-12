require "test_helper"

class AutomationRuleTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:automation_rule).valid?
  end

  test "name presence and length" do
    refute build(:automation_rule, name: nil).valid?
    refute build(:automation_rule, name: "a").valid?
    refute build(:automation_rule, name: "x" * 201).valid?
  end

  test "trigger_type inclusion" do
    refute build(:automation_rule, trigger_type: "nope").valid?
    assert build(:automation_rule, trigger_type: "tag_based").valid?
    assert build(:automation_rule, trigger_type: "time_based").valid?
  end

  test "delay_hours must be non-negative" do
    refute build(:automation_rule, delay_hours: -1).valid?
    assert build(:automation_rule, delay_hours: 0).valid?
  end

  test "active and inactive scopes" do
    active = create(:automation_rule, active: true)
    inactive = create(:automation_rule, active: false)
    assert_includes AutomationRule.active, active
    assert_includes AutomationRule.inactive, inactive
  end

  test "activate and deactivate" do
    rule = create(:automation_rule, active: false)
    rule.activate
    assert rule.reload.active
    rule.deactivate
    refute rule.reload.active
  end

  test "tag_based? and time_based? predicates" do
    assert build(:automation_rule, trigger_type: "tag_based").tag_based?
    assert build(:automation_rule, trigger_type: "time_based").time_based?
    refute build(:automation_rule, trigger_type: "time_based").tag_based?
  end

  test "already_executed_for? returns true if any execution exists" do
    rule = create(:automation_rule)
    contact = create(:contact, organization: rule.organization)
    refute rule.already_executed_for?(contact)
    create(:automation_execution, automation_rule: rule, contact: contact)
    assert rule.already_executed_for?(contact)
  end

  test "dispatch_for! creates a campaign send and enqueues the job" do
    rule = create(:automation_rule)
    contact = create(:contact, organization: rule.organization)

    assert_enqueued_with(job: SendEmailJob) do
      send = rule.dispatch_for!(contact)
      assert send.present?
      assert_equal "queued", send.status
    end

    assert_equal 1, rule.automation_executions.where(contact: contact).count
  end

  test "dispatch_for! returns nil if already executed" do
    rule = create(:automation_rule)
    contact = create(:contact, organization: rule.organization)
    rule.dispatch_for!(contact)
    assert_nil rule.dispatch_for!(contact)
  end
end
