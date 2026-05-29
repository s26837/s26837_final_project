class InvitationsController < ApplicationController
  skip_before_action :require_authentication, only: [:accept, :show]
  before_action :set_organization, only: [:new, :create]
  before_action :require_admin, only: [:new, :create]
  before_action :set_invitation_by_token, only: [:accept, :show]

  def new
    @invitation = @organization.invitations.new
  end

  def create
    @organization = Organization.find(params[:organization_id])
    @invitation = @organization.invitations.new(role: invitation_params[:role] || 'member')

    if @invitation.save
      render json: {
        success: true,
        invitation_url: show_invitation_url(token: @invitation.token)
      }
    else
      render json: {
        success: false,
        error: @invitation.errors.full_messages.to_sentence
      }, status: :unprocessable_entity
    end
  end
  def show
    if @invitation.expired?
      redirect_to root_path, alert: "This invitation link has expired"
      return
    end

    if current_user
      if @organization.organization_memberships.exists?(user: current_user)
        redirect_to @organization, notice: "You are already a member of #{@organization.name}"
      else
        @organization.organization_memberships.create!(user: current_user, role: @invitation.role || 'member')
        redirect_to @organization, notice: "Successfully joined #{@organization.name}!"
      end
    else
      @user = User.new
      render 'accept'
    end
  end


  def accept
    if @invitation.expired?
      redirect_to root_path, alert: "This invitation link has expired"
      return
    end

    @user = User.new(user_params)

    if @user.save
      session = @user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      @organization.organization_memberships.create!(user: @user, role: @invitation.role || 'member')

      redirect_to @organization, notice: "Welcome to #{@organization.name}!"
    else
      render 'accept', status: :unprocessable_entity
    end
  end

  private

  def set_invitation_by_token
    @invitation = Invitation.find_by!(token: params[:token])
    @organization = @invitation.organization
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid invitation link"
  end

  def invitation_params
    params.require(:invitation).permit(:role)
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
