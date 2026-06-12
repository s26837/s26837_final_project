ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include ActiveJob::TestHelper

    setup do
      CampaignSend.singleton_class.alias_method(:_original_broadcast_subscribed_views_for, :broadcast_subscribed_views_for) unless CampaignSend.singleton_class.method_defined?(:_original_broadcast_subscribed_views_for)
      CampaignSend.singleton_class.send(:define_method, :broadcast_subscribed_views_for) { |_| nil }
    end
  end
end

class ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  def sign_in(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end

  def switch_to(organization)
    post switch_organization_path(organization)
  end
end
