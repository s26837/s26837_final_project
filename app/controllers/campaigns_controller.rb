class CampaignsController < ApplicationController
  before_action :set_organization
  before_action :load_org_templates, only: [:new, :create, :edit, :update]
  before_action :load_org_tags,      only: [:new, :create, :edit, :update]
  before_action :set_campaign, only: [:show, :edit, :update, :destroy, :send_now]

  def index
    @campaigns = @organization.campaigns
                              .where.not(status: 'automated')
                              .includes(steps: :email_template)
                              .order(created_at: :desc)
  end

  def show
    @sends = @campaign.campaign_sends
                      .where.not(campaign_step_id: nil)
                      .includes(:contact, :email_events)
                      .order(created_at: :desc)
                      .limit(100)
    @stats = @campaign.stats
    @projected_recipient_count = @campaign.target_contacts.count if @campaign.status.in?(%w[draft scheduled])
  end

  def new
    @campaign = @organization.campaigns.new
    if params[:contact_ids].present?
      ids = Array(params[:contact_ids]).map(&:to_i) & @organization.contacts.pluck(:id)
      ids.each { |cid| @campaign.campaign_contacts.build(contact_id: cid) }
    end
  end

  def create
    @campaign = @organization.campaigns.new(campaign_params)
    @campaign.created_by = current_user.id
    @campaign.status = 'scheduled' if @campaign.scheduled_at.present?

    desired_steps    = parse_step_params
    desired_tags     = parse_tag_ids
    desired_contacts = parse_contact_ids

    if desired_steps.empty?
      @campaign.errors.add(:base, "Add at least one email template to the sequence")
      return render_form_with_errors(:new)
    end

    saved = false
    ActiveRecord::Base.transaction do
      @campaign.save!
      desired_steps.each_with_index { |attrs, i| @campaign.steps.create!(attrs.merge(position: i)) }
      sync_campaign_tags(@campaign, desired_tags)
      sync_campaign_contacts(@campaign, desired_contacts)
      saved = true
    end

    if saved
      enqueue_scheduled_send(@campaign)
      redirect_to organization_campaign_path(@organization, @campaign), notice: scheduling_notice(@campaign, "Campaign created")
    else
      render_form_with_errors(:new)
    end
  rescue ActiveRecord::RecordInvalid
    render_form_with_errors(:new)
  end

  def edit
  end

  def update
    new_attrs = campaign_params
    if new_attrs[:scheduled_at].present?
      @campaign.status = 'scheduled' if @campaign.status == 'draft'
    elsif @campaign.scheduled?
      @campaign.status = 'draft'
    end

    @campaign.assign_attributes(new_attrs)

    desired_steps    = parse_step_params
    desired_tags     = parse_tag_ids
    desired_contacts = parse_contact_ids

    if desired_steps.empty?
      @campaign.errors.add(:base, "Add at least one email template to the sequence")
      return render_form_with_errors(:edit)
    end

    saved = false
    ActiveRecord::Base.transaction do
      @campaign.save!
      @campaign.steps.destroy_all
      desired_steps.each_with_index { |attrs, i| @campaign.steps.create!(attrs.merge(position: i)) }
      sync_campaign_tags(@campaign, desired_tags)
      sync_campaign_contacts(@campaign, desired_contacts)
      saved = true
    end

    if saved
      enqueue_scheduled_send(@campaign)
      redirect_to organization_campaign_path(@organization, @campaign), notice: scheduling_notice(@campaign, "Campaign updated")
    else
      render_form_with_errors(:edit)
    end
  rescue ActiveRecord::RecordInvalid
    render_form_with_errors(:edit)
  end

  def destroy
    @campaign.destroy
    redirect_to organization_campaigns_path(@organization), notice: "Campaign deleted successfully"
  end

  def send_now
    result = CampaignDispatcher.dispatch(@campaign)
    redirect_to organization_campaign_path(@organization, @campaign), notice: result.notice
  end

  private

  def parse_step_params
    raw = params.dig(:campaign, :steps)
    return [] if raw.blank?

    valid_template_ids = @organization.email_templates.pluck(:id).to_set
    rows = raw.respond_to?(:values) ? raw.values : Array(raw)
    rows.filter_map do |row|
      row = row.to_unsafe_h if row.respond_to?(:to_unsafe_h)
      template_id = (row[:email_template_id] || row["email_template_id"]).to_i
      next unless valid_template_ids.include?(template_id)
      delay = (row[:delay_hours] || row["delay_hours"]).to_i.clamp(0, 24 * 365)
      { email_template_id: template_id, delay_hours: delay }
    end
  end

  def parse_tag_ids
    submitted = Array(params[:tag_ids]).map(&:to_i).reject(&:zero?).uniq
    return [] if submitted.empty?
    @organization.tags.where(id: submitted).pluck(:id)
  end

  def parse_contact_ids
    submitted = Array(params[:contact_ids]).map(&:to_i).reject(&:zero?).uniq
    return [] if submitted.empty?
    @organization.contacts.where(id: submitted).pluck(:id)
  end

  def sync_campaign_tags(campaign, tag_ids)
    campaign.campaign_tags.destroy_all
    tag_ids.each { |tid| campaign.campaign_tags.create!(tag_id: tid) }
  end

  def sync_campaign_contacts(campaign, contact_ids)
    campaign.campaign_contacts.destroy_all
    contact_ids.each { |cid| campaign.campaign_contacts.create!(contact_id: cid) }
  end

  def render_form_with_errors(action)
    render action, status: :unprocessable_entity
  end

  def enqueue_scheduled_send(campaign)
    return unless campaign.scheduled? && campaign.scheduled_at.present?

    ScheduledCampaignJob
      .set(wait_until: campaign.scheduled_at)
      .perform_later(campaign.id, campaign.scheduled_at.to_i)
  end

  def scheduling_notice(campaign, base)
    if campaign.scheduled?
      "#{base}. Scheduled to send #{campaign.scheduled_at.strftime('%B %d, %Y at %I:%M %p %Z')}."
    else
      "#{base} successfully"
    end
  end

  def set_campaign
    @campaign = @organization.campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:name, :scheduled_at)
  end
end
