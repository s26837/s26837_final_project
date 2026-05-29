class CreateContactTags < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_tags do |t|
      t.bigint :contact_id, null: false
      t.bigint :tag_id, null: false

      t.timestamps
    end
    add_index :contact_tags, :contact_id
    add_index :contact_tags, :tag_id
    add_index :contact_tags, [:contact_id, :tag_id], unique: true, name: 'index_contact_tags_on_contact_and_tag'
    add_foreign_key :contact_tags, :contacts
    add_foreign_key :contact_tags, :tags
  end
end
