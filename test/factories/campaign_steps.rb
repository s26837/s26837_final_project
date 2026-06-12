FactoryBot.define do
  factory :campaign_step do
    association :campaign
    email_template { association :email_template, organization: campaign.organization }
    sequence(:position) { |n| n - 1 }
    delay_hours { 0 }
  end
end
