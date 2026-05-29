class DemoKeyUsage < ApplicationRecord
  DAILY_LIMIT = 100
  TIME_ZONE   = "Europe/Warsaw".freeze

  def self.current
    first_or_create!
  end

  def self.increment_if_allowed!
    transaction do
      record = lock.first_or_create!
      record.reset_if_due!
      return false if record.count >= DAILY_LIMIT
      record.update!(count: record.count + 1)
      true
    end
  end

  def self.reset!
    current.update!(count: 0, last_reset_at: Time.current)
  end

  def self.remaining
    [DAILY_LIMIT - current.count, 0].max
  end

  def reset_if_due!
    tz = ActiveSupport::TimeZone[TIME_ZONE]
    today_midnight = tz.now.beginning_of_day
    if last_reset_at.nil? || last_reset_at < today_midnight
      update!(count: 0, last_reset_at: Time.current)
    end
  end
end
