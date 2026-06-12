FactoryBot.define do
  factory :automation_execution do
    association :automation_rule
    contact { association :contact, organization: automation_rule.organization }
    status { "pending" }
  end
end
