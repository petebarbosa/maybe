class Provider::FrankfurterExchangeRates < Provider
  include ExchangeRateConcept

  CRYPTO_CODES = %w[BTC ETH].freeze

  Error = Class.new(Provider::Error)

  BASE_URL = "https://api.frankfurter.app".freeze

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      if CRYPTO_CODES.include?(from) || CRYPTO_CODES.include?(to)
        raise Error, "Frankfurter does not support crypto currencies: #{from}/#{to}"
      end

      response = @conn.get("/v1/#{date}/#{from}")
      rates = response.body["rates"][to]

      Rate.new(date: date, from: from, to: to, rate: rates)
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      if CRYPTO_CODES.include?(from) || CRYPTO_CODES.include?(to)
        raise Error, "Frankfurter does not support crypto currencies: #{from}/#{to}"
      end

      response = @conn.get("/v1/#{start_date}..#{end_date}", { from: from, to: to })
      rates = response.body["rates"]

      rates.map do |date_str, rate_data|
        Rate.new(
          date: Date.parse(date_str),
          from: from,
          to: to,
          rate: rate_data[to]
        )
      end
    end
  end
end
