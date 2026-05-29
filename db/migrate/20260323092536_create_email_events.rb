class CreateEmailEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :email_events do |t|
      t.bigint :campaign_send_id, null: false
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.string :url
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
    add_index :email_events, :campaign_send_id
    add_index :email_events, :event_type
    add_index :email_events, :occurred_at
    add_foreign_key :email_events, :campaign_sends
  end
end
