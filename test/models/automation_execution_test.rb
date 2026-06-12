require "test_helper"

class AutomationExecutionTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:automation_execution).valid?
  end

  test "status must be in allowed set" do
    refute build(:automation_execution, status: "unknown").valid?
  end

  test "uniqueness scoped to contact" do
    rule = create(:automation_rule)
    contact = create(:contact, organization: rule.organization)
    create(:automation_execution, automation_rule: rule, contact: contact)
    dup = build(:automation_execution, automation_rule: rule, contact: contact)
    refute dup.valid?
  end

  test "execute! transitions pending to completed" do
    execution = create(:automation_execution, status: "pending")
    execution.execute!
    assert execution.completed?
    assert_not_nil execution.executed_at
  end

  test "execute! is a no-op for non-pending" do
    execution = create(:automation_execution, status: "pending")
    execution.update!(status: "completed", executed_at: Time.current)
    expected_time = execution.executed_at
    execution.execute!
    assert_equal expected_time.to_i, execution.executed_at.to_i
  end

  test "pending? completed? failed? predicates" do
    assert build(:automation_execution, status: "pending").pending?
    assert build(:automation_execution, status: "completed").completed?
    assert build(:automation_execution, status: "failed").failed?
  end

  test "ready_to_execute? respects delay_hours" do
    rule = create(:automation_rule, delay_hours: 2)
    execution = create(:automation_execution, automation_rule: rule, status: "pending")
    refute execution.ready_to_execute?
    execution.update_column(:created_at, 3.hours.ago)
    assert execution.reload.ready_to_execute?
  end
end
