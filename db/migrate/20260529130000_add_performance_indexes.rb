class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :email_events,
              [:campaign_send_id, :event_type, :occurred_at],
              name: "index_email_events_on_send_type_time"

    add_index :contact_tags,
              [:tag_id, :created_at],
              name: "index_contact_tags_on_tag_and_created_at"
  end
end
