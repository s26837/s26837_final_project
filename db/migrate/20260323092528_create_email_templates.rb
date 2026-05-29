class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.bigint :organization_id, null: false
      t.string :name, null: false
      t.string :subject
      t.text :html_content
      t.text :text_content

      t.timestamps
    end
    add_index :email_templates, :organization_id
    add_foreign_key :email_templates, :organizations
  end
end
