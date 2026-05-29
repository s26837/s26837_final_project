class AddSendgridApiKeyToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :sendgrid_api_key, :string
  end
end
