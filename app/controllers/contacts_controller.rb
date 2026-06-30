class ContactsController < ApplicationController
  MAX_IMPORT_BYTES = 5.megabytes
  ALLOWED_IMPORT_CONTENT_TYPES = %w[
    text/csv
    application/csv
    application/vnd.ms-excel
    text/plain
  ].freeze

  before_action :set_organization
  before_action :load_org_tags, only: [:index, :import]
  before_action :set_contact, only: [:show, :edit, :update, :destroy, :add_tag, :remove_tag]

  def index
    @contacts = @organization.contacts.includes(:tags)
    if params[:tag_id].present?
      @contacts = @contacts.joins(:tags).where(tags: { id: params[:tag_id] })
    end

    @contacts = @contacts.search_by_name_or_email(params[:search]) if params[:search].present?

    @contacts = @contacts.order(created_at: :desc).limit(1000)
  end

  def show
    @email_events = @contact.campaign_sends.includes(:email_events, :campaign, campaign_step: :email_template)
                            .order(created_at: :desc).limit(20)
  end

  def new
    @contact = @organization.contacts.new
  end

  def create
    @contact = @organization.contacts.new(contact_params)
    
    if @contact.save
      redirect_to organization_contacts_path(@organization), notice: "Contact created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to organization_contact_path(@organization, @contact), notice: "Contact updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to organization_contacts_path(@organization), notice: "Contact deleted successfully"
  end

  def import
  end

  def process_import
    file = params[:csv_file]
    if file.blank?
      redirect_to import_organization_contacts_path(@organization), alert: "Please select a CSV file"
      return
    end

    reject = csv_upload_rejection(file)
    if reject
      redirect_to import_organization_contacts_path(@organization), alert: reject
      return
    end

    tag_name = params[:tag_name]
    result = ContactImporter.call(organization: @organization, file: file, tag_name: tag_name)

    if result.success?
      flash[:notice] = "Successfully imported #{result.imported_count} contacts"
      flash[:notice] += " and tagged them as '#{tag_name}'" if tag_name.present?
      flash[:notice] += ". Skipped #{result.skipped_count} incomplete rows" if result.skipped_count.positive?
    else
      flash[:alert] = "Imported #{result.imported_count} contacts"
      flash[:alert] += ", skipped #{result.skipped_count} incomplete rows" if result.skipped_count.positive?
      flash[:alert] += ". Errors: #{result.errors.first(5).join('; ')}"
    end

    redirect_to organization_contacts_path(@organization)
  end

  def bulk_destroy
    tag_id = params[:tag_id]
    
    if tag_id.present?
      contacts = @organization.contacts.joins(:tags).where(tags: { id: tag_id })
      count = contacts.count
      contacts.destroy_all
      redirect_to organization_contacts_path(@organization), notice: "Deleted #{count} contacts"
    else
      redirect_to organization_contacts_path(@organization), alert: "Please select a tag"
    end
  end

  def add_tag
    tag = @organization.tags.find(params[:tag_id])

    unless @contact.tags.include?(tag)
      @contact.tags << tag
      trigger_tag_automations_for(@contact, tag)
    end

    respond_to do |format|
      format.html { redirect_to organization_contact_path(@organization, @contact), notice: "Tag added" }
      format.json { render json: { success: true } }
    end
  end

  def remove_tag
    tag = @contact.tags.find(params[:tag_id])
    @contact.tags.delete(tag)

    respond_to do |format|
      format.html { redirect_to organization_contact_path(@organization, @contact), notice: "Tag removed" }
      format.json { render json: { success: true } }
    end
  end

  private

  def csv_upload_rejection(file)
    if file.size > MAX_IMPORT_BYTES
      return "File is too large (max #{MAX_IMPORT_BYTES / 1.megabyte} MB)"
    end

    content_type = file.content_type.to_s
    looks_like_csv = ALLOWED_IMPORT_CONTENT_TYPES.include?(content_type) ||
                     File.extname(file.original_filename.to_s).downcase == ".csv"
    return "Please upload a CSV file" unless looks_like_csv

    nil
  end

  def set_contact
    @contact = @organization.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:email, :first_name, :last_name)
  end

  def trigger_tag_automations_for(contact, tag)
    @organization.automation_rules
                 .active
                 .tag_based
                 .where("trigger_conditions ->> 'tag_id' = ?", tag.id.to_s)
                 .find_each do |rule|
      rule.dispatch_for!(contact, async: false)
    rescue => e
      Rails.logger.error "Instant automation dispatch failed for rule #{rule.id}, contact #{contact.id}: #{e.message}"
    end
  end
end
