require "test_helper"

class Provider::OpencodeExchangeRatesTest < ActiveSupport::TestCase
  setup do
    @provider = Provider::OpencodeExchangeRates.new
  end

  test "symbol normalization converts XBT to BTC" do
    assert_equal "BTC", @provider.send(:normalize_symbol, "XBT")
    assert_equal "BTC", @provider.send(:normalize_symbol, "xbt")
    assert_equal "ETH", @provider.send(:normalize_symbol, "ETH")
  end

  test "allowlist validation accepts valid hosts" do
    valid_hosts = %w[www.ecb.europa.eu www.bankofcanada.ca www.imf.org api.exchange.coinbase.com api.kraken.com]
    valid_hosts.each do |host|
      assert_includes Provider::OpencodeExchangeRates::ALLOWLIST_HOSTS, host
    end
  end

  test "extract_host parses URLs correctly" do
    assert_equal "www.ecb.europa.eu", @provider.send(:extract_host, "https://www.ecb.europa.eu/stats/rates.xml")
    assert_equal "api.kraken.com", @provider.send(:extract_host, "https://api.kraken.com/0/public/OHLC")
    result = @provider.send(:extract_host, "not-a-url")
    assert_nil result
  end

  test "validation rejects missing required keys" do
    parsed = { "rates" => [ { "date" => "2026-04-01" } ] }
    assert_raises(Provider::OpencodeExchangeRates::ValidationError) do
      @provider.send(:validate_response!, parsed, "USD", "EUR", Date.current - 5.days, Date.current)
    end
  end

  test "validation rejects out-of-range dates" do
    parsed = {
      "rates" => [
        { "date" => "2020-01-01", "rate" => "1.2", "source_url" => "https://www.ecb.europa.eu/rates", "source_name" => "ECB" }
      ]
    }
    assert_raises(Provider::OpencodeExchangeRates::ValidationError) do
      @provider.send(:validate_response!, parsed, "USD", "EUR", Date.current - 5.days, Date.current)
    end
  end

  test "validation rejects non-allowlisted source" do
    parsed = {
      "rates" => [
        { "date" => Date.current.to_s, "rate" => "1.2", "source_url" => "https://sketchy-source.com/rates", "source_name" => "Unknown" }
      ]
    }
    assert_raises(Provider::OpencodeExchangeRates::ValidationError) do
      @provider.send(:validate_response!, parsed, "USD", "EUR", Date.current - 5.days, Date.current)
    end
  end

  test "validation rejects negative or zero rates" do
    parsed = {
      "rates" => [
        { "date" => Date.current.to_s, "rate" => "-1.2", "source_url" => "https://www.ecb.europa.eu/rates", "source_name" => "ECB" }
      ]
    }
    assert_raises(Provider::OpencodeExchangeRates::ValidationError) do
      @provider.send(:validate_response!, parsed, "USD", "EUR", Date.current - 5.days, Date.current)
    end
  end

  test "validation rejects empty rates array" do
    parsed = { "rates" => [] }
    assert_raises(Provider::OpencodeExchangeRates::ValidationError) do
      @provider.send(:validate_response!, parsed, "USD", "EUR", Date.current - 5.days, Date.current)
    end
  end

  test "parse_json_response extracts JSON from markdown" do
    text = "Here are the rates:\n```json\n{\"from\":\"USD\",\"to\":\"EUR\",\"rates\":[{\"date\":\"2026-04-01\",\"rate\":0.92,\"source_url\":\"https://www.ecb.europa.eu\",\"source_name\":\"ECB\"}]}\n```"
    parsed = @provider.send(:parse_json_response, text)

    assert_equal "USD", parsed["from"]
    assert_equal "EUR", parsed["to"]
    assert_equal 1, parsed["rates"].size
  end

  test "parse_json_response handles bare JSON" do
    text = "{\"from\":\"USD\",\"to\":\"EUR\",\"rates\":[]}"
    parsed = @provider.send(:parse_json_response, text)

    assert_equal "USD", parsed["from"]
  end

  test "parse_json_response returns empty hash for invalid JSON" do
    text = "This is not JSON at all"
    parsed = @provider.send(:parse_json_response, text)

    assert_equal({}, parsed)
  end

  test "prompt includes internet lookup instruction and allowlist" do
    prompt = @provider.send(:build_prompt, "USD", "EUR", Date.current - 3.days, Date.current)

    assert_includes prompt, "internet lookup"
    assert_includes prompt, "www.ecb.europa.eu"
    assert_includes prompt, "api.kraken.com"
    assert_includes prompt, "UTC 00:00"
  end
end
