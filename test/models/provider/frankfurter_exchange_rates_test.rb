require "test_helper"

class Provider::FrankfurterExchangeRatesTest < ActiveSupport::TestCase
  setup do
    @subject = Provider::FrankfurterExchangeRates.new
  end

  test "fetch_exchange_rate returns provider response with one rate" do
    stub_request(:get, /api\.frankfurter\.app\/v1\/2024-01-15\/USD/)
      .to_return(
        status: 200,
        body: { "rates" => { "EUR" => 0.91 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @subject.fetch_exchange_rate(
      from: "USD",
      to: "EUR",
      date: Date.parse("2024-01-15")
    )

    assert response.success?
    rate = response.data
    assert_equal "USD", rate.from
    assert_equal "EUR", rate.to
    assert_equal Date.parse("2024-01-15"), rate.date
    assert_operator rate.rate, :>, 0
  end

  test "fetch_exchange_rates returns multiple rates for date range" do
    stub_request(:get, /api\.frankfurter\.app\/v1\/2024-01-01\.\.2024-01-05/)
      .with(query: { "from" => "USD", "to" => "EUR" })
      .to_return(
        status: 200,
        body: {
          "rates" => {
            "2024-01-01" => { "EUR" => 0.91 },
            "2024-01-02" => { "EUR" => 0.92 },
            "2024-01-03" => { "EUR" => 0.90 }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @subject.fetch_exchange_rates(
      from: "USD",
      to: "EUR",
      start_date: Date.parse("2024-01-01"),
      end_date: Date.parse("2024-01-05")
    )

    assert response.success?
    assert_operator response.data.count, :>, 0
    assert response.data.all? { |rate| rate.from == "USD" && rate.to == "EUR" }
  end

  test "fetch_exchange_rate returns error for crypto pair" do
    response = @subject.fetch_exchange_rate(
      from: "BTC",
      to: "USD",
      date: Date.current
    )

    assert_not response.success?
    assert_includes response.error.message, "BTC"
  end
end
