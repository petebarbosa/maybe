require "test_helper"

class Provider::FreecryptoExchangeRatesTest < ActiveSupport::TestCase
  test "raises error when api_key is nil" do
    error = assert_raises(ArgumentError) do
      Provider::FreecryptoExchangeRates.new(api_key: nil)
    end
    assert_includes error.message, "api_key is required"
  end

  test "raises error when api_key is empty string" do
    error = assert_raises(ArgumentError) do
      Provider::FreecryptoExchangeRates.new(api_key: "")
    end
    assert_includes error.message, "api_key is required"
  end

  test "raises error when api_key is whitespace only" do
    error = assert_raises(ArgumentError) do
      Provider::FreecryptoExchangeRates.new(api_key: "   ")
    end
    assert_includes error.message, "api_key is required"
  end

  test "uses Authorization header with API key" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    stub_request(:get, /api\.freecryptoapi\.com/)
      .with(headers: { "Authorization" => "Bearer test_api_key" })
      .to_return(
        status: 200,
        body: { "data" => { "BTC" => { "USD" => 67000.00 } } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    subject.fetch_exchange_rate(from: "BTC", to: "USD", date: Date.current)
  end

  test "fetch_exchange_rate returns today rate for crypto pair" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    stub_request(:get, /api\.freecryptoapi\.com\/v1\/crypto\/price/)
      .with(query: { "fsym" => "BTC", "tsyms" => "USD" })
      .to_return(
        status: 200,
        body: {
          "data" => {
            "BTC" => { "USD" => 67000.00 }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = subject.fetch_exchange_rate(
      from: "BTC",
      to: "USD",
      date: Date.current
    )

    assert response.success?
    assert_equal "BTC", response.data.from
    assert_equal "USD", response.data.to
    assert_operator response.data.rate, :>, 0
  end

  test "fetch_exchange_rates returns only today for free tier" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    stub_request(:get, /api\.freecryptoapi\.com\/v1\/crypto\/price/)
      .to_return(
        status: 200,
        body: {
          "data" => {
            "BTC" => { "USD" => 67000.00 }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = subject.fetch_exchange_rates(
      from: "BTC",
      to: "USD",
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert response.success?
    assert_equal 1, response.data.count
    assert_equal Date.current, response.data.first.date
  end

  test "fetch_exchange_rate returns error for historical date" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    response = subject.fetch_exchange_rate(
      from: "BTC",
      to: "USD",
      date: 30.days.ago.to_date
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "historical"
  end

  test "fetch_exchange_rate returns error for future date" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    response = subject.fetch_exchange_rate(
      from: "BTC",
      to: "USD",
      date: 30.days.from_now.to_date
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "future"
  end

  test "fetch_exchange_rates returns error when end_date is before today" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    response = subject.fetch_exchange_rates(
      from: "BTC",
      to: "USD",
      start_date: 60.days.ago.to_date,
      end_date: 30.days.ago.to_date
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "historical"
  end

  test "fetch_exchange_rates returns error when start_date is in future" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    response = subject.fetch_exchange_rates(
      from: "BTC",
      to: "USD",
      start_date: 30.days.from_now.to_date,
      end_date: 60.days.from_now.to_date
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "future"
  end

  test "fetch_exchange_rate returns error when price is missing" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    stub_request(:get, /api\.freecryptoapi\.com\/v1\/crypto\/price/)
      .to_return(
        status: 200,
        body: { "data" => {} }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = subject.fetch_exchange_rate(
      from: "BTC",
      to: "USD",
      date: Date.current
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "no price"
  end

  test "fetch_exchange_rates returns error when price is missing" do
    subject = Provider::FreecryptoExchangeRates.new(api_key: "test_api_key")

    stub_request(:get, /api\.freecryptoapi\.com\/v1\/crypto\/price/)
      .to_return(
        status: 200,
        body: { "data" => {} }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = subject.fetch_exchange_rates(
      from: "BTC",
      to: "USD",
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_not response.success?
    assert_includes response.error.message.downcase, "no price"
  end
end
