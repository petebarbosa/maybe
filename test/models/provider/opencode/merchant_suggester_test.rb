require "test_helper"

class Provider::Opencode::MerchantSuggesterTest < ActiveSupport::TestCase
  setup do
    @client = mock("client")
    @user_merchants = [
      { id: "merchant-1", name: "Plaza Vea" },
      { id: "merchant-2", name: "Wong" }
    ]
  end

  test "suggest returns MerchantSuggestion on success" do
    session_response = { "id" => "sess_suggest" }
    message_response = {
      "info" => {
        "structured_output" => {
          "merchant_id" => "merchant-1",
          "confidence" => 0.85,
          "rationale" => "PLVAA PLVAL matches Plaza Vea pattern"
        }
      }
    }

    @client.expects(:create_session).with(title: "suggest-merchant").returns(session_response)
    @client.expects(:send_message).returns(message_response)
    @client.expects(:delete_session).with("sess_suggest")

    suggester = Provider::Opencode::MerchantSuggester.new(
      @client,
      raw_name: "PLVAA PLVAL",
      normalized_name: "PLVAA PLVAL",
      user_merchants: @user_merchants
    )

    result = suggester.suggest
    assert_equal "merchant-1", result.merchant_id
    assert_equal 0.85, result.confidence
    assert_equal "PLVAA PLVAL matches Plaza Vea pattern", result.rationale
  end

  test "suggest handles null merchant_id" do
    session_response = { "id" => "sess_suggest" }
    message_response = {
      "info" => {
        "structured_output" => {
          "merchant_id" => nil,
          "confidence" => 0.3,
          "rationale" => "No confident match found"
        }
      }
    }

    @client.expects(:create_session).returns(session_response)
    @client.expects(:send_message).returns(message_response)
    @client.expects(:delete_session).with("sess_suggest")

    suggester = Provider::Opencode::MerchantSuggester.new(
      @client,
      raw_name: "UNKNOWN",
      normalized_name: "UNKNOWN",
      user_merchants: @user_merchants
    )

    result = suggester.suggest
    assert_nil result.merchant_id
    assert_equal 0.3, result.confidence
  end

  test "suggest handles API errors gracefully" do
    @client.expects(:create_session).raises(StandardError.new("API error"))

    suggester = Provider::Opencode::MerchantSuggester.new(
      @client,
      raw_name: "PLVAA PLVAL",
      normalized_name: "PLVAA PLVAL",
      user_merchants: @user_merchants
    )

    assert_raises(StandardError) do
      suggester.suggest
    end
  end
end
