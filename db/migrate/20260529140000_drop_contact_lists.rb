class DropContactLists < ActiveRecord::Migration[8.0]
  def up
    drop_table :contact_list_memberships, if_exists: true
    drop_table :contact_lists,            if_exists: true
  end

  def down
    create_table :contact_lists do |t|
      t.bigint :organization_id, null: false
      t.string :name,            null: false
      t.text   :description
      t.timestamps
      t.index :organization_id
    end

    create_table :contact_list_memberships do |t|
      t.bigint :contact_id,      null: false
      t.bigint :contact_list_id, null: false
      t.timestamps
      t.index [:contact_id, :contact_list_id], unique: true, name: "index_contact_list_memberships_on_contact_and_list"
      t.index :contact_id
      t.index :contact_list_id
    end

    add_foreign_key :contact_lists,            :organizations
    add_foreign_key :contact_list_memberships, :contacts
    add_foreign_key :contact_list_memberships, :contact_lists
  end
end
