Rails.application.config.after_initialize do
  unless defined?(Rails::Console) || Rails.env.test? || File.basename($0) == 'rake'
    Thread.new do
      loop do
        sleep 1.hour
        AutomationProcessorJob.perform_later
      end
    rescue => e
      Rails.logger.error "Automation scheduler error: #{e.message}"
      retry
    end
  end
end
