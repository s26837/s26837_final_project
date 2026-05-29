class EmailTemplatesController < ApplicationController
  before_action :set_organization
  before_action :set_template, only: [:show, :edit, :update, :destroy]

  def index
    @templates = @organization.email_templates.order(created_at: :desc)
  end

  def show
  end

  def new
    @template = @organization.email_templates.new
  end

  def create
    @template = @organization.email_templates.new(template_params)
    apply_blocks_param(@template)

    if @template.save
      redirect_to organization_email_templates_path(@organization), notice: "Email template created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @template.assign_attributes(template_params)
    apply_blocks_param(@template)

    if @template.save
      redirect_to organization_email_templates_path(@organization), notice: "Email template updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to organization_email_templates_path(@organization), notice: "Email template deleted successfully"
  end

  private

  def set_template
    @template = @organization.email_templates.find(params[:id])
  end

  def template_params
    params.require(:email_template).permit(:name, :subject, :html_content, :text_content)
  end

  def apply_blocks_param(template)
    raw = params[:blocks_json]
    return if raw.blank?

    parsed = JSON.parse(raw)
    template.blocks = parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    template.errors.add(:base, "Could not read the visual builder content")
  end
end
