class CreateCampaignSends < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_sends do |t|
      t.bigint :campaign_id, null: false
      t.bigint :contact_id, null: false
      t.string :sendgrid_message_id
      t.string :status, default: 'queued'
      t.datetime :delivered_at

      t.timestamps
    end
    add_index :campaign_sends, :campaign_id
    add_index :campaign_sends, :contact_id
    add_index :campaign_sends, :sendgrid_message_id
    add_index :campaign_sends, :status
    add_index :campaign_sends, [:campaign_id, :contact_id], unique: true, name: 'index_campaign_sends_on_campaign_and_contact'
    add_foreign_key :campaign_sends, :campaigns
    add_foreign_key :campaign_sends, :contacts
  end
end
