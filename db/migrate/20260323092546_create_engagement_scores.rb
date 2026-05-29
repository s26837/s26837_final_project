class CreateEngagementScores < ActiveRecord::Migration[8.0]
  def change
    create_table :engagement_scores do |t|
      t.bigint :contact_id, null: false
      t.integer :opens_count, default: 0
      t.integer :clicks_count, default: 0
      t.float :composite_score, default: 0.0
      t.datetime :last_engaged_at

      t.timestamps
    end
    add_index :engagement_scores, :contact_id, unique: true
    add_index :engagement_scores, :composite_score
    add_foreign_key :engagement_scores, :contacts
  end
end
