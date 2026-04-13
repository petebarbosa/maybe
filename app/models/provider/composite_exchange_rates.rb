class Provider::CompositeExchangeRates < Provider
  include ExchangeRateConcept

  CRYPTO_CODES = %w[BTC ETH SOL].freeze

  def initialize(frankfurter: nil, freecrypto: nil)
    @frankfurter = frankfurter || Provider::FrankfurterExchangeRates.new
    @freecrypto = freecrypto
  end

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      provider_response = provider_for(from: from, to: to).fetch_exchange_rate(from: from, to: to, date: date)
      raise provider_response.error unless provider_response.success?

      provider_response.data
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      provider_response = provider_for(from: from, to: to).fetch_exchange_rates(from: from, to: to, start_date: start_date, end_date: end_date)
      raise provider_response.error unless provider_response.success?

      provider_response.data
    end
  end

  private

    def provider_for(from:, to:)
      if crypto_involved?(from) || crypto_involved?(to)
        raise self.class::Error, "Freecrypto API key not configured" unless @freecrypto.present?

        @freecrypto
      else
        @frankfurter
      end
    end

    def crypto_involved?(code)
      CRYPTO_CODES.include?(code)
    end
end
