FactoryBot.define do
  factory :tag do
    association :organization
    sequence(:name) { |n| "tag-#{n}" }
    color { "#4F46E5" }
  end
end
