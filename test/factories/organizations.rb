FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Org #{n}" }
    description { "An organization for testing" }
    association :owner, factory: :user

    trait :with_demo_sendgrid do
      sendgrid_demo { true }
    end

    trait :with_custom_sendgrid do
      sendgrid_api_key { "SG.custom-test-key" }
    end
  end
end
