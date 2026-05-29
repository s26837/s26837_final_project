require "test_helper"

class SendEmailJobTest < ActiveJob::TestCase
  setup do
    skip "SENDGRID_DEMO_API_KEY not set in .env" if ENV["SENDGRID_DEMO_API_KEY"].blank?

    @recipient = ENV.fetch("TEST_EMAIL_RECIPIENT", "s26837@pjwstk.edu.pl")

    @owner = User.create!(
      email: "owner-#{SecureRandom.hex(4)}@example.com",
      name: "Owner",
      password: "password123"
    )

    @organization = Organization.create!(
      name: "Acme Co",
      owner: @owner,
      sendgrid_demo: true
    )

    @contact = Contact.create!(
      organization: @organization,
      email: @recipient,
      first_name: "Test"
    )

    @template = EmailTemplate.create!(
      organization: @organization,
      name: "Test Send",
      subject: "Test email from SendEmailJob (#{Time.current.iso8601})",
      html_content: "<p>Hi, this is a real test send from the SendEmailJob test.</p>",
      text_content: "Hi, this is a real test send from the SendEmailJob test."
    )

    @campaign = Campaign.create!(
      organization: @organization,
      creator: @owner,
      name: "Test Campaign"
    )

    @campaign_step = CampaignStep.create!(
      campaign: @campaign,
      email_template: @template,
      position: 0,
      delay_hours: 0
    )

    @campaign_send = CampaignSend.create!(
      campaign: @campaign,
      campaign_step: @campaign_step,
      contact: @contact
    )
  end

  test "sends a real email through SendGrid and marks the CampaignSend as sent" do
    log_io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_io)

    begin
      SendEmailJob.perform_now(@campaign_send.id)
    ensure
      Rails.logger = original_logger
    end

    @campaign_send.reload
    assert_equal "sent", @campaign_send.status,
      "expected status=sent, got #{@campaign_send.status}.\nLogger output:\n#{log_io.string}"
    assert_not_nil @campaign_send.sendgrid_message_id, "expected a SendGrid message id"
    assert_not_nil @campaign_send.delivered_at
  end
end
