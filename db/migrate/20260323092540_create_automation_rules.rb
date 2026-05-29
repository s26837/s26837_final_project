class CreateAutomationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :automation_rules do |t|
      t.bigint :organization_id, null: false
      t.bigint :email_template_id, null: false
      t.string :name, null: false
      t.string :trigger_type, null: false
      t.jsonb :trigger_conditions, default: {}
      t.integer :delay_hours, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :automation_rules, :organization_id
    add_index :automation_rules, :email_template_id
    add_index :automation_rules, :trigger_type
    add_index :automation_rules, :active
    add_foreign_key :automation_rules, :organizations
    add_foreign_key :automation_rules, :email_templates
  end
end
