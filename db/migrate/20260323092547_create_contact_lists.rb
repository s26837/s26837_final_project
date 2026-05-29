class CreateContactLists < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_lists do |t|
      t.bigint :organization_id, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :contact_lists, :organization_id
    add_foreign_key :contact_lists, :organizations
  end
end
