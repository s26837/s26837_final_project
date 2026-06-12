FactoryBot.define do
  factory :webhook_log do
    event_type { "delivered" }
    payload { { "event" => "delivered", "sg_message_id" => "msg-1", "timestamp" => Time.current.to_i } }
    processed { false }
  end
end
