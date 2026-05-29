class RegistrationsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session = @user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      organization = Organization.create!(
        name: "#{@user.name}'s Organization",
        owner: @user
      )
      set_current_organization(organization)
      redirect_to root_path, notice: "Welcome! Your organization has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
