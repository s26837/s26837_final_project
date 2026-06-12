FactoryBot.define do
  factory :contact do
    association :organization
    sequence(:email) { |n| "contact#{n}@example.com" }
    first_name { "Jane" }
    last_name { "Doe" }
  end
end
