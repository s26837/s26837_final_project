class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :update, :switch, :set_sendgrid_key, :leave]
  before_action :require_admin, only: [:update, :set_sendgrid_key]

  def show
  end

  def update
    if @organization.update(organization_params)
      redirect_to @organization, notice: "Organization updated successfully"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def leave
    if current_user.owner_of?(@organization)
      redirect_to @organization, alert: "The organization owner can't leave their own organization."
      return
    end

    membership = @organization.organization_memberships.find_by(user: current_user)
    if membership
      membership.destroy
      session[:current_organization_id] = nil
      redirect_to root_path, notice: "You have left #{@organization.name}."
    else
      redirect_to root_path
    end
  end

  def switch
    set_current_organization(@organization)
    redirect_to @organization, notice: "Switched to #{@organization.name}"
  end

  def set_sendgrid_key
    redirect_target = params[:return_to].presence == "settings" ? organization_path(@organization) : root_path

    if params[:use_demo].present?
      if ENV["SENDGRID_DEMO_API_KEY"].blank?
        redirect_to redirect_target, alert: "Demo key is not configured on this server." and return
      end
      @organization.update!(sendgrid_demo: true)
      redirect_to redirect_target, notice: "Switched to demo SendGrid key." and return
    end

    key = params[:sendgrid_api_key].to_s.strip
    if key.blank?
      redirect_to redirect_target, alert: "No SendGrid key provided." and return
    end

    @organization.update!(sendgrid_api_key: key, sendgrid_demo: false)
    redirect_to redirect_target, notice: "Custom SendGrid key saved."
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:id])
  end

  def require_admin
    unless current_user.admin_of?(@organization)
      redirect_to @organization, alert: "Only organization admins can change these settings."
    end
  end

  def organization_params
    params.require(:organization).permit(:name, :description)
  end
end
