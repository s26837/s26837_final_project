class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.bigint :organization_id, null: false
      t.string :name, null: false
      t.string :color

      t.timestamps
    end
    add_index :tags, :organization_id
    add_index :tags, [:organization_id, :name], unique: true, name: 'index_tags_on_org_and_name'
    add_foreign_key :tags, :organizations
  end
end
