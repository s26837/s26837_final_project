class DashboardController < ApplicationController
  def index
    if current_organization.nil?
      org = Organization.create!(name: "#{current_user.name}'s Organization", owner: current_user)
      set_current_organization(org)
    end

    @organization = current_organization
    @contact_count    = @organization.contacts.count
    @template_count   = @organization.email_templates.count
    @campaign_count   = @organization.campaigns.count
    @automation_count = @organization.automation_rules.where(active: true).count

    @recent_campaigns = @organization.campaigns.order(created_at: :desc).limit(5)
    @recent_contacts  = @organization.contacts.order(created_at: :desc).limit(10)

    @total_sent  = @organization.campaigns.joins(:campaign_sends).count
    @total_opens = @organization.campaigns.joins(campaign_sends: :email_events)
                                .where(email_events: { event_type: 'opened' }).distinct.count
    @total_clicks = @organization.campaigns.joins(campaign_sends: :email_events)
                                 .where(email_events: { event_type: 'clicked' }).distinct.count
  end
end
