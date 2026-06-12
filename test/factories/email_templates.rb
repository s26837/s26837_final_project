FactoryBot.define do
  factory :email_template do
    association :organization
    sequence(:name) { |n| "Template #{n}" }
    subject { "Welcome to our service" }
    html_content { "<p>Hello there!</p>" }
    text_content { "Hello there!" }

    trait :with_blocks do
      blocks {
        [
          { "type" => "heading", "level" => 1, "text" => "Welcome" },
          { "type" => "paragraph", "text" => "Hello world" }
        ]
      }
    end
  end
end
