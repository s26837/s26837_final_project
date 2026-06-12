require "test_helper"

class DemoKeyUsageTest < ActiveSupport::TestCase
  setup do
    DemoKeyUsage.delete_all
  end

  test "current creates a record on first call" do
    assert_difference "DemoKeyUsage.count", 1 do
      DemoKeyUsage.current
    end
  end

  test "current returns the same record on subsequent calls" do
    a = DemoKeyUsage.current
    b = DemoKeyUsage.current
    assert_equal a.id, b.id
  end

  test "increment_if_allowed! increments below limit" do
    DemoKeyUsage.current.update!(count: 0, last_reset_at: Time.current)
    assert DemoKeyUsage.increment_if_allowed!
    assert_equal 1, DemoKeyUsage.current.count
  end

  test "increment_if_allowed! refuses at limit" do
    DemoKeyUsage.current.update!(count: DemoKeyUsage::DAILY_LIMIT, last_reset_at: Time.current)
    refute DemoKeyUsage.increment_if_allowed!
    assert_equal DemoKeyUsage::DAILY_LIMIT, DemoKeyUsage.current.count
  end

  test "remaining reflects usage" do
    DemoKeyUsage.current.update!(count: 10, last_reset_at: Time.current)
    assert_equal DemoKeyUsage::DAILY_LIMIT - 10, DemoKeyUsage.remaining
  end

  test "remaining is never negative" do
    DemoKeyUsage.current.update!(count: DemoKeyUsage::DAILY_LIMIT + 5, last_reset_at: Time.current)
    assert_equal 0, DemoKeyUsage.remaining
  end

  test "reset! zeros count and updates last_reset_at" do
    DemoKeyUsage.current.update!(count: 50, last_reset_at: 1.week.ago)
    DemoKeyUsage.reset!
    record = DemoKeyUsage.current
    assert_equal 0, record.count
    assert record.last_reset_at > 1.minute.ago
  end

  test "reset_if_due! resets when last_reset_at is before today midnight" do
    record = DemoKeyUsage.current
    record.update!(count: 7, last_reset_at: 2.days.ago)
    record.reset_if_due!
    assert_equal 0, record.reload.count
  end

  test "reset_if_due! does nothing if reset already happened today" do
    tz = ActiveSupport::TimeZone[DemoKeyUsage::TIME_ZONE]
    record = DemoKeyUsage.current
    record.update!(count: 9, last_reset_at: tz.now)
    record.reset_if_due!
    assert_equal 9, record.reload.count
  end
end
