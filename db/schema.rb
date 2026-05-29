# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_29_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "automation_executions", force: :cascade do |t|
    t.bigint "automation_rule_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "campaign_send_id"
    t.datetime "executed_at"
    t.string "status", default: "pending"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["automation_rule_id", "contact_id"], name: "index_automation_executions_on_rule_and_contact", unique: true
    t.index ["automation_rule_id"], name: "index_automation_executions_on_automation_rule_id"
    t.index ["campaign_send_id"], name: "index_automation_executions_on_campaign_send_id"
    t.index ["contact_id"], name: "index_automation_executions_on_contact_id"
    t.index ["status"], name: "index_automation_executions_on_status"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "email_template_id", null: false
    t.string "name", null: false
    t.string "trigger_type", null: false
    t.jsonb "trigger_conditions", default: {}
    t.integer "delay_hours", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_automation_rules_on_active"
    t.index ["email_template_id"], name: "index_automation_rules_on_email_template_id"
    t.index ["organization_id"], name: "index_automation_rules_on_organization_id"
    t.index ["trigger_type"], name: "index_automation_rules_on_trigger_type"
  end

  create_table "campaign_contacts", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "contact_id"], name: "index_campaign_contacts_on_campaign_id_and_contact_id", unique: true
    t.index ["campaign_id"], name: "index_campaign_contacts_on_campaign_id"
    t.index ["contact_id"], name: "index_campaign_contacts_on_contact_id"
  end

  create_table "campaign_sends", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "contact_id", null: false
    t.string "sendgrid_message_id"
    t.string "status", default: "queued"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "campaign_step_id"
    t.index ["campaign_id"], name: "index_campaign_sends_on_campaign_id"
    t.index ["campaign_step_id", "contact_id"], name: "index_campaign_sends_on_step_and_contact", unique: true
    t.index ["campaign_step_id"], name: "index_campaign_sends_on_campaign_step_id"
    t.index ["contact_id"], name: "index_campaign_sends_on_contact_id"
    t.index ["sendgrid_message_id"], name: "index_campaign_sends_on_sendgrid_message_id"
    t.index ["status"], name: "index_campaign_sends_on_status"
  end

  create_table "campaign_steps", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "email_template_id", null: false
    t.integer "position", null: false
    t.integer "delay_hours", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "position"], name: "index_campaign_steps_on_campaign_id_and_position", unique: true
    t.index ["campaign_id"], name: "index_campaign_steps_on_campaign_id"
    t.index ["email_template_id"], name: "index_campaign_steps_on_email_template_id"
  end

  create_table "campaign_tags", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "tag_id"], name: "index_campaign_tags_on_campaign_and_tag", unique: true
    t.index ["campaign_id"], name: "index_campaign_tags_on_campaign_id"
    t.index ["tag_id"], name: "index_campaign_tags_on_tag_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "created_by", null: false
    t.string "name", null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.string "status", default: "draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "index_campaigns_on_created_by"
    t.index ["organization_id"], name: "index_campaigns_on_organization_id"
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "contact_tags", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "tag_id"], name: "index_contact_tags_on_contact_and_tag", unique: true
    t.index ["contact_id"], name: "index_contact_tags_on_contact_id"
    t.index ["tag_id", "created_at"], name: "index_contact_tags_on_tag_and_created_at"
    t.index ["tag_id"], name: "index_contact_tags_on_tag_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["organization_id", "email"], name: "index_contacts_on_org_and_email", unique: true
    t.index ["organization_id"], name: "index_contacts_on_organization_id"
  end

  create_table "demo_key_usages", force: :cascade do |t|
    t.integer "count", default: 0, null: false
    t.datetime "last_reset_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "email_events", force: :cascade do |t|
    t.bigint "campaign_send_id", null: false
    t.string "event_type", null: false
    t.datetime "occurred_at", null: false
    t.string "url"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_send_id", "event_type", "occurred_at"], name: "index_email_events_on_send_type_time"
    t.index ["campaign_send_id"], name: "index_email_events_on_campaign_send_id"
    t.index ["event_type"], name: "index_email_events_on_event_type"
    t.index ["occurred_at"], name: "index_email_events_on_occurred_at"
  end

  create_table "email_templates", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "subject"
    t.text "html_content"
    t.text "text_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "blocks", default: []
    t.index ["organization_id"], name: "index_email_templates_on_organization_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "token", null: false
    t.string "role", default: "member"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_org_memberships_on_user_and_org", unique: true
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sendgrid_api_key"
    t.boolean "sendgrid_demo", default: false, null: false
    t.index ["owner_id"], name: "index_organizations_on_owner_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_tags_on_org_and_name", unique: true
    t.index ["organization_id"], name: "index_tags_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_logs", force: :cascade do |t|
    t.string "event_type", null: false
    t.jsonb "payload", default: {}
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_logs_on_created_at"
    t.index ["event_type"], name: "index_webhook_logs_on_event_type"
    t.index ["processed"], name: "index_webhook_logs_on_processed"
  end

  add_foreign_key "automation_executions", "automation_rules"
  add_foreign_key "automation_executions", "campaign_sends"
  add_foreign_key "automation_executions", "contacts"
  add_foreign_key "automation_rules", "email_templates"
  add_foreign_key "automation_rules", "organizations"
  add_foreign_key "campaign_contacts", "campaigns"
  add_foreign_key "campaign_contacts", "contacts"
  add_foreign_key "campaign_sends", "campaign_steps"
  add_foreign_key "campaign_sends", "campaigns"
  add_foreign_key "campaign_sends", "contacts"
  add_foreign_key "campaign_steps", "campaigns"
  add_foreign_key "campaign_steps", "email_templates"
  add_foreign_key "campaign_tags", "campaigns"
  add_foreign_key "campaign_tags", "tags"
  add_foreign_key "campaigns", "organizations"
  add_foreign_key "campaigns", "users", column: "created_by"
  add_foreign_key "contact_tags", "contacts"
  add_foreign_key "contact_tags", "tags"
  add_foreign_key "contacts", "organizations"
  add_foreign_key "email_events", "campaign_sends"
  add_foreign_key "email_templates", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "organizations", "users", column: "owner_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tags", "organizations"
end
