class CreateWebhookLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_logs do |t|
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.boolean :processed, default: false

      t.timestamps
    end
    add_index :webhook_logs, :event_type
    add_index :webhook_logs, :processed
    add_index :webhook_logs, :created_at
  end
end
