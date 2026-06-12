FactoryBot.define do
  factory :campaign do
    association :organization
    creator { organization.owner }
    sequence(:name) { |n| "Campaign #{n}" }
    status { "draft" }

    trait :scheduled do
      status { "scheduled" }
      scheduled_at { 1.day.from_now }
    end

    trait :sent do
      status { "sent" }
      sent_at { Time.current }
    end

    trait :automated do
      status { "automated" }
    end
  end
end
