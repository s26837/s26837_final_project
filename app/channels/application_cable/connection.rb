# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session_token = cookies.signed[:session_token]
      if session_token && (session = Session.find_by(id: session_token))
        session.user
      else
        reject_unauthorized_connection
      end
    end
  end
end
