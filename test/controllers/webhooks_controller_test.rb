require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "stripe webhook returns ok no-op when payments disabled" do
    with_payments_enabled(false) do
      post webhooks_stripe_path
      assert_response :success
    end
  end
end
