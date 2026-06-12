FactoryBot.define do
  factory :automation_rule do
    association :organization
    email_template { association :email_template, organization: organization }
    sequence(:name) { |n| "Rule #{n}" }
    trigger_type { "tag_based" }
    trigger_conditions { { "tag_id" => 1 } }
    delay_hours { 0 }
    active { true }
  end
end
