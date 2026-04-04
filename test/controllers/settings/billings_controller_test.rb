require "test_helper"

class Settings::BillingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "billing page redirects to root when payments disabled" do
    with_payments_enabled(false) { get settings_billing_path }
    assert_redirected_to root_path
  end
end
