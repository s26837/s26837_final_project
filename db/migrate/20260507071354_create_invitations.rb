class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, default: 'member'
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
