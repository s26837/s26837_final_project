class SimplifyInvitations < ActiveRecord::Migration[8.0]
  def change
    remove_index  :invitations, :email, if_exists: true
    remove_column :invitations, :email,       :string
    remove_column :invitations, :accepted_at, :datetime
  end
end
