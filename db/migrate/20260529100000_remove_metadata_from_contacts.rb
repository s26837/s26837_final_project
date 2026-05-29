class RemoveMetadataFromContacts < ActiveRecord::Migration[8.0]
  def change
    remove_column :contacts, :metadata, :jsonb, default: {}
  end
end
