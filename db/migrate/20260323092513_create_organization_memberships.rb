class CreateOrganizationMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_memberships do |t|
      t.bigint :user_id, null: false
      t.bigint :organization_id, null: false
      t.string :role, null: false, default: 'member'

      t.timestamps
    end
    add_index :organization_memberships, :user_id
    add_index :organization_memberships, :organization_id
    add_index :organization_memberships, [:user_id, :organization_id], unique: true, name: 'index_org_memberships_on_user_and_org'
    add_foreign_key :organization_memberships, :users
    add_foreign_key :organization_memberships, :organizations
  end
end
