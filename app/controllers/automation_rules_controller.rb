class AutomationRulesController < ApplicationController
  before_action :set_organization
  before_action :require_admin
  before_action :load_org_templates, only: [:new, :create, :edit, :update]
  before_action :load_org_tags,      only: [:new, :create, :edit, :update]
  before_action :set_rule, only: [:show, :edit, :update, :destroy]

  def index
    @rules = @organization.automation_rules.includes(:email_template).order(created_at: :desc)
  end

  def show
    @executions = @rule.automation_executions.includes(:contact).order(created_at: :desc).limit(50)
  end

  def new
    @rule = @organization.automation_rules.new
  end

  def create
    @rule = @organization.automation_rules.new(rule_params)

    if @rule.save
      sent_count = backfill_existing_contacts(@rule)
      notice = "Automation rule created successfully"
      notice += " sent to #{sent_count} existing contact#{'s' unless sent_count == 1}" if sent_count.positive?
      redirect_to organization_automation_rules_path(@organization), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @rule.update(rule_params)
      redirect_to organization_automation_rules_path(@organization), notice: "Automation rule updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy
    redirect_to organization_automation_rules_path(@organization), notice: "Automation rule deleted successfully"
  end

  private

  def set_rule
    @rule = @organization.automation_rules.find(params[:id])
  end

  def rule_params
    params.require(:automation_rule).permit(
      :name, :trigger_type, :email_template_id, :delay_hours, :active,
      trigger_conditions: [:tag_id, :inactivity_hours, :segment_tag_id]
    )
  end

  def backfill_existing_contacts(rule)
    return 0 unless rule.active? && rule.tag_based?

    tag_id = rule.trigger_conditions["tag_id"]
    return 0 if tag_id.blank?

    eligible = @organization.contacts
                            .joins(:contact_tags)
                            .where(contact_tags: { tag_id: tag_id })
                            .where.not(id: rule.automation_executions.select(:contact_id))

    sent = 0
    eligible.find_each do |contact|
      rule.dispatch_for!(contact, async: true)
      sent += 1
    rescue => e
      Rails.logger.error "Backfill dispatch failed for rule #{rule.id}, contact #{contact.id}: #{e.message}"
    end
    sent
  end
end
