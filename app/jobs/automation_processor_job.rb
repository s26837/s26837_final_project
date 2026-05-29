class AutomationProcessorJob < ApplicationJob
  queue_as :default

  def perform
    AutomationRule.where(active: true).find_each do |rule|
      case rule.trigger_type
      when "tag_based"  then process_tag_rule(rule)
      when "time_based" then process_inactivity_rule(rule)
      end
    rescue => e
      Rails.logger.error "Automation processing failed for rule #{rule.id}: #{e.message}"
    end
  end

  private

  def process_tag_rule(rule)
    tag_id = rule.trigger_conditions["tag_id"]
    return unless tag_id

    delay_hours = rule.delay_hours || 0
    organization = rule.organization

    eligible = organization.contacts
                           .joins(:contact_tags)
                           .where(contact_tags: { tag_id: tag_id })
                           .where("contact_tags.created_at <= ?", delay_hours.hours.ago)
                           .where.not(id: rule.automation_executions.select(:contact_id))

    dispatch_rule(rule, eligible)
  end

  def process_inactivity_rule(rule)
    hours = rule.trigger_conditions["inactivity_hours"].to_i
    return if hours <= 0

    cutoff = hours.hours.ago
    organization = rule.organization

    scope = organization.contacts.where.not(id: rule.automation_executions.select(:contact_id))

    if (segment_tag_id = rule.trigger_conditions["segment_tag_id"]).present?
      scope = scope.joins(:contact_tags).where(contact_tags: { tag_id: segment_tag_id }).distinct
    end

    scope = scope.where(<<~SQL.squish, cutoff: cutoff)
      contacts.created_at <= :cutoff
      AND NOT EXISTS (
        SELECT 1 FROM email_events
        INNER JOIN campaign_sends ON campaign_sends.id = email_events.campaign_send_id
        WHERE campaign_sends.contact_id = contacts.id
          AND email_events.event_type IN ('opened', 'clicked')
          AND email_events.occurred_at > :cutoff
      )
    SQL

    dispatch_rule(rule, scope)
  end

  def dispatch_rule(rule, contacts_scope)
    contacts_scope.find_each { |contact| rule.dispatch_for!(contact, async: true) }
  end
end
