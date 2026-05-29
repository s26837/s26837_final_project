class DropEngagementScores < ActiveRecord::Migration[8.0]
  def up
    drop_table :engagement_scores, if_exists: true
  end

  def down
    create_table :engagement_scores do |t|
      t.bigint :contact_id, null: false
      t.integer :opens_count, default: 0
      t.integer :clicks_count, default: 0
      t.float :composite_score, default: 0.0
      t.datetime :last_engaged_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index :composite_score, name: "index_engagement_scores_on_composite_score"
      t.index :contact_id, name: "index_engagement_scores_on_contact_id", unique: true
    end
  end
end
