class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.bigint :organization_id, null: false
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :contacts, :organization_id
    add_index :contacts, :email
    add_index :contacts, [:organization_id, :email], unique: true, name: 'index_contacts_on_org_and_email'
    add_foreign_key :contacts, :organizations
  end
end
