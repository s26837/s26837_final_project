class MakeInvitationEmailOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :invitations, :email, true
  end
end
