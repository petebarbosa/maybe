class Provider::FreecryptoExchangeRates < Provider
  include ExchangeRateConcept

  CRYPTO_CODES = %w[BTC ETH SOL].freeze

  Error = Class.new(Provider::Error)

  BASE_URL = "https://api.freecryptoapi.com".freeze

  def initialize(api_key:)
    raise ArgumentError, "api_key is required" if api_key.nil? || api_key.to_s.strip.empty?

    @api_key = api_key
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.headers["Authorization"] = "Bearer #{api_key}"
    end
  end

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      raise_error_unless_today(date)

      price = fetch_price(from: from, to: to)
      raise Error, "No price data returned for #{from}/#{to}" if price.nil?

      Rate.new(date: Date.current, from: from, to: to, rate: price)
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      if start_date > Date.current
        raise Error, "FreeCryptoAPI does not support future dates"
      end

      if end_date < Date.current
        raise Error, "FreeCryptoAPI does not support historical rates. Only current date is available."
      end

      price = fetch_price(from: from, to: to)
      raise Error, "No price data returned for #{from}/#{to}" if price.nil?

      [
        Rate.new(
          date: Date.current,
          from: from,
          to: to,
          rate: price
        )
      ]
    end
  end

  private

    def raise_error_unless_today(date)
      raise Error, "FreeCryptoAPI does not support historical rates" if date < Date.current
      raise Error, "FreeCryptoAPI does not support future dates" if date > Date.current
    end

    def fetch_price(from:, to:)
      response = @conn.get("/v1/crypto/price", { fsym: from, tsyms: to })
      response.body.dig("data", from, to)
    end
end
