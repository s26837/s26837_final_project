FactoryBot.define do
  factory :email_event do
    association :campaign_send
    event_type { "opened" }
    occurred_at { Time.current }
  end
end
