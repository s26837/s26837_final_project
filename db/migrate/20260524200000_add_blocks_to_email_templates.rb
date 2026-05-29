class AddBlocksToEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :email_templates, :blocks, :jsonb, default: []
  end
end
