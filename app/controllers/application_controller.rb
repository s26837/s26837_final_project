class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :require_authentication

  private

  def current_session
    @current_session ||= Session.find_by(id: cookies.signed[:session_token]) if cookies.signed[:session_token]
  end

  def current_user
    @current_user ||= current_session&.user
  end
  helper_method :current_user

  def user_signed_in?
    current_user.present?
  end
  helper_method :user_signed_in?

  def require_authentication
    unless user_signed_in?
      redirect_to login_path, alert: "You must be signed in to access this page"
    end
  end

  def current_organization
    @current_organization ||= begin
      org_id = session[:current_organization_id]
      if org_id
        current_user.organizations.find_by(id: org_id)
      else
        current_user.organizations.first
      end
    end
  end
  helper_method :current_organization

  def set_current_organization(organization)
    session[:current_organization_id] = organization.id
    @current_organization = organization
  end

  def require_admin
    unless current_user.admin_of?(current_organization)
      redirect_to root_path, alert: "You don't have permission to access this page"
    end
  end

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def load_org_templates
    @templates = @organization.email_templates.order(:name)
  end

  def load_org_tags
    @tags = @organization.tags.order(:name)
  end
end
