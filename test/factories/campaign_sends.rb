FactoryBot.define do
  factory :campaign_send do
    association :campaign
    contact { association :contact, organization: campaign.organization }
    status { "queued" }
  end
end
