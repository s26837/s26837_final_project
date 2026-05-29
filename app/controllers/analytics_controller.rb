class AnalyticsController < ApplicationController
  before_action :set_organization

  DELIVERED_STATUSES = %w[sent delivered].freeze

  def index
    load_overall_stats
    load_recent_campaigns
    load_tag_segment_stats
  end

  private

  def load_overall_stats
    @total_contacts  = @organization.contacts.count
    @total_campaigns = @organization.campaigns.count

    campaign_sends_in_org = CampaignSend.joins(:campaign).where(campaigns: { organization_id: @organization.id })

    @total_attempts  = campaign_sends_in_org.count
    @total_sent      = campaign_sends_in_org.where(status: DELIVERED_STATUSES).count
    @delivered_count = @total_sent

    send_ids = campaign_sends_in_org.where(status: DELIVERED_STATUSES).pluck(:id)

    @opened_count  = EmailEvent.where(campaign_send_id: send_ids, event_type: 'opened').distinct.pluck(:campaign_send_id).count
    @clicked_count = EmailEvent.where(campaign_send_id: send_ids, event_type: 'clicked').distinct.pluck(:campaign_send_id).count

    @delivery_rate = percent(@total_sent,    @total_attempts)
    @open_rate     = percent(@opened_count,  @total_sent)
    @click_rate    = percent(@clicked_count, @total_sent)
  end

  def load_recent_campaigns
    campaigns = @organization.campaigns
                             .where.not(sent_at: nil)
                             .order(sent_at: :desc)
                             .limit(10)
                             .to_a

    @recent_campaigns = decorate_with_send_stats(campaigns)
  end

  def decorate_with_send_stats(campaigns)
    ids = campaigns.map(&:id)
    return [] if ids.empty?

    sends_scope     = CampaignSend.where(campaign_id: ids)
    delivered_scope = sends_scope.where(status: DELIVERED_STATUSES)

    totals    = sends_scope.group(:campaign_id).count
    delivered = delivered_scope.group(:campaign_id).count
    opens     = delivered_scope.joins(:email_events).where(email_events: { event_type: 'opened' })
                               .distinct.group(:campaign_id).count(:id)
    clicks    = delivered_scope.joins(:email_events).where(email_events: { event_type: 'clicked' })
                               .distinct.group(:campaign_id).count(:id)

    campaigns.map do |campaign|
      {
        campaign:  campaign,
        total:     totals[campaign.id].to_i,
        delivered: delivered[campaign.id].to_i,
        opened:    opens[campaign.id].to_i,
        clicked:   clicks[campaign.id].to_i
      }
    end
  end

  def load_tag_segment_stats
    delivered_list = DELIVERED_STATUSES.map { |s| "'#{s}'" }.join(", ")

    rows = @organization.tags
                        .left_joins(contacts: { campaign_sends: :email_events })
                        .group("tags.id")
                        .pluck(
                          "tags.id",
                          Arel.sql("COUNT(DISTINCT contacts.id)"),
                          Arel.sql("COUNT(DISTINCT CASE WHEN campaign_sends.status IN (#{delivered_list}) THEN campaign_sends.id END)"),
                          Arel.sql("COUNT(DISTINCT CASE WHEN email_events.event_type = 'opened'  AND campaign_sends.status IN (#{delivered_list}) THEN email_events.campaign_send_id END)"),
                          Arel.sql("COUNT(DISTINCT CASE WHEN email_events.event_type = 'clicked' AND campaign_sends.status IN (#{delivered_list}) THEN email_events.campaign_send_id END)")
                        )

    stats_by_id = rows.to_h { |id, *counts| [id, counts] }

    @tag_stats = @organization.tags.order(:name).map do |tag|
      contact_count, sends, opens, clicks = stats_by_id[tag.id] || [0, 0, 0, 0]
      {
        tag: tag,
        contact_count: contact_count,
        emails_sent:   sends,
        open_rate:     percent(opens,  sends),
        click_rate:    percent(clicks, sends)
      }
    end
  end

  def percent(numerator, denominator)
    return 0 if denominator.to_i.zero?
    (numerator.to_f / denominator * 100).round(2)
  end
end
