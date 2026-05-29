class CreateCampaignTags < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_tags do |t|
      t.bigint :campaign_id, null: false
      t.bigint :tag_id, null: false

      t.timestamps
    end
    add_index :campaign_tags, :campaign_id
    add_index :campaign_tags, :tag_id
    add_index :campaign_tags, [:campaign_id, :tag_id], unique: true, name: 'index_campaign_tags_on_campaign_and_tag'
    add_foreign_key :campaign_tags, :campaigns
    add_foreign_key :campaign_tags, :tags
  end
end
