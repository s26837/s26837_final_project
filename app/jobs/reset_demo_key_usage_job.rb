class ResetDemoKeyUsageJob < ApplicationJob
  queue_as :default

  def perform
    DemoKeyUsage.reset!
    Rails.logger.info "DemoKeyUsage counter reset (midnight #{DemoKeyUsage::TIME_ZONE})"
  end
end
