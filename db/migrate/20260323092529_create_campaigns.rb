class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.bigint :organization_id, null: false
      t.bigint :created_by, null: false
      t.bigint :email_template_id
      t.string :name, null: false
      t.string :subject
      t.text :html_content
      t.text :text_content
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.string :status, default: 'draft'

      t.timestamps
    end
    add_index :campaigns, :organization_id
    add_index :campaigns, :created_by
    add_index :campaigns, :email_template_id
    add_index :campaigns, :status
    add_foreign_key :campaigns, :organizations
    add_foreign_key :campaigns, :users, column: :created_by
    add_foreign_key :campaigns, :email_templates
  end
end
