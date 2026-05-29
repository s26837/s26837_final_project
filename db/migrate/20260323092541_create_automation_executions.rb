class CreateAutomationExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :automation_executions do |t|
      t.bigint :automation_rule_id, null: false
      t.bigint :contact_id, null: false
      t.bigint :campaign_send_id
      t.datetime :executed_at
      t.string :status, default: 'pending'
      t.text :error_message

      t.timestamps
    end
    add_index :automation_executions, :automation_rule_id
    add_index :automation_executions, :contact_id
    add_index :automation_executions, :campaign_send_id
    add_index :automation_executions, :status
    add_index :automation_executions, [:automation_rule_id, :contact_id], unique: true, name: 'index_automation_executions_on_rule_and_contact'
    add_foreign_key :automation_executions, :automation_rules
    add_foreign_key :automation_executions, :contacts
    add_foreign_key :automation_executions, :campaign_sends
  end
end
