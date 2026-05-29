class MembersController < ApplicationController
  before_action :set_organization
  before_action :require_admin
  before_action :set_member, only: [:destroy, :promote_to_admin]

  def index
    @members = @organization.organization_memberships.includes(:user).order(created_at: :desc)
  end

  def destroy
    if @member.user == @organization.owner
      redirect_to organization_members_path(@organization), alert: "Cannot remove the organization owner"
    elsif @member.user == current_user
      redirect_to organization_members_path(@organization), alert: "Cannot remove yourself"
    else
      @member.destroy
      redirect_to organization_members_path(@organization), notice: "Member removed successfully"
    end
  end

  def promote_to_admin
    if @member.update(role: 'admin')
      redirect_to organization_members_path(@organization), notice: "Member promoted to admin successfully"
    else
      redirect_to organization_members_path(@organization), alert: "Failed to promote member"
    end
  end

  private

  def set_member
    @member = @organization.organization_memberships.find(params[:id])
  end
end
