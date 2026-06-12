FactoryBot.define do
  factory :organization_membership do
    association :user
    association :organization
    role { "member" }

    trait :admin do
      role { "admin" }
    end

    trait :owner do
      role { "owner" }
    end
  end
end
