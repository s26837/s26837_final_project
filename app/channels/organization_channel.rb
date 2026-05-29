class OrganizationChannel < ApplicationCable::Channel
  def subscribed
    organization = current_user.organizations.find(params[:organization_id])
    stream_from "organization_#{organization.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
