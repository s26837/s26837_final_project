class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session = user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      redirect_to root_path, notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Signed out successfully"
  end
end
