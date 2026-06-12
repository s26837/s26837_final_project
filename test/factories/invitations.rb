FactoryBot.define do
  factory :invitation do
    association :organization
    role { "member" }
  end
end
