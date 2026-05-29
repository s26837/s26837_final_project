class CreateCampaignSteps < ActiveRecord::Migration[8.0]
  def up
    create_table :campaign_steps do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :email_template, null: false, foreign_key: true
      t.integer :position, null: false
      t.integer :delay_hours, null: false, default: 0
      t.timestamps
    end
    add_index :campaign_steps, [:campaign_id, :position], unique: true
    add_reference :campaign_sends, :campaign_step, foreign_key: true, null: true
    remove_index :campaign_sends, name: :index_campaign_sends_on_campaign_and_contact
    add_index :campaign_sends, [:campaign_step_id, :contact_id],
              unique: true, name: :index_campaign_sends_on_step_and_contact

    execute(<<~SQL)
      INSERT INTO campaign_steps (campaign_id, email_template_id, position, delay_hours, created_at, updated_at)
      SELECT c.id, c.email_template_id, 0, 0, NOW(), NOW()
      FROM campaigns c
      WHERE c.email_template_id IS NOT NULL
    SQL

    say_with_time "Migrating inline campaign content into templates" do
      Campaign.reset_column_information
      ActiveRecord::Base.connection.exec_query(
        "SELECT id, organization_id, name, subject, html_content, text_content FROM campaigns " \
        "WHERE email_template_id IS NULL AND html_content IS NOT NULL AND html_content <> ''"
      ).each do |row|
        template_id = ActiveRecord::Base.connection.insert(
          ActiveRecord::Base.sanitize_sql_array([
            "INSERT INTO email_templates (organization_id, name, subject, html_content, text_content, created_at, updated_at) " \
            "VALUES (?, ?, ?, ?, ?, NOW(), NOW())",
            row["organization_id"],
            "Legacy: #{row['name']}",
            row["subject"].presence || row["name"],
            row["html_content"],
            row["text_content"]
          ])
        )
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
            "INSERT INTO campaign_steps (campaign_id, email_template_id, position, delay_hours, created_at, updated_at) " \
            "VALUES (?, ?, 0, 0, NOW(), NOW())",
            row["id"], template_id
          ])
        )
      end
    end

    execute(<<~SQL)
      UPDATE campaign_sends cs
      SET campaign_step_id = steps.id
      FROM campaign_steps steps
      WHERE steps.campaign_id = cs.campaign_id
        AND steps.position = 0
        AND cs.campaign_step_id IS NULL
    SQL

    remove_reference :campaigns, :email_template, foreign_key: true
    remove_column :campaigns, :subject, :string
    remove_column :campaigns, :html_content, :text
    remove_column :campaigns, :text_content, :text
  end

  def down
    add_column :campaigns, :text_content, :text
    add_column :campaigns, :html_content, :text
    add_column :campaigns, :subject, :string
    add_reference :campaigns, :email_template, foreign_key: true, null: true

    execute(<<~SQL)
      UPDATE campaigns c
      SET email_template_id = steps.email_template_id
      FROM campaign_steps steps
      WHERE steps.campaign_id = c.id AND steps.position = 0
    SQL

    remove_index :campaign_sends, name: :index_campaign_sends_on_step_and_contact
    add_index :campaign_sends, [:campaign_id, :contact_id],
              unique: true, name: :index_campaign_sends_on_campaign_and_contact

    remove_reference :campaign_sends, :campaign_step, foreign_key: true
    drop_table :campaign_steps
  end
end
