class CreateContactListMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_list_memberships do |t|
      t.bigint :contact_id, null: false
      t.bigint :contact_list_id, null: false

      t.timestamps
    end
    add_index :contact_list_memberships, :contact_id
    add_index :contact_list_memberships, :contact_list_id
    add_index :contact_list_memberships, [:contact_id, :contact_list_id], unique: true, name: 'index_contact_list_memberships_on_contact_and_list'
    add_foreign_key :contact_list_memberships, :contacts
    add_foreign_key :contact_list_memberships, :contact_lists
  end
end
