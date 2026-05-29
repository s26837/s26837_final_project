class PagesController < ApplicationController
  skip_before_action :require_authentication

  def home
    if user_signed_in?
      redirect_to root_path
    end
  end
end
