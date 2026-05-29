class CreateCampaignContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_contacts do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :contact,  null: false, foreign_key: true
      t.timestamps
    end
    add_index :campaign_contacts, [:campaign_id, :contact_id], unique: true
  end
end
