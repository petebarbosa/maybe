class Import::MerchantResolution
  Resolution = Data.define(:transaction_descriptor, :merchant, :method, :confidence, :needs_review)

  def initialize(family, transactions)
    @family = family
    @transactions = transactions
    @resolver = MerchantResolver.new(family)
  end

  def resolve_all
    @transactions.map do |txn|
      descriptor = txn[:merchant_descriptor] || txn[:name] || "Unknown"
      result = @resolver.resolve(descriptor)

      Resolution.new(
        transaction_descriptor: descriptor,
        merchant: result.merchant,
        method: result.method,
        confidence: result.confidence,
        needs_review: result.method == :needs_user_resolution || result.method == :no_match
      )
    end
  end

  def resolutions_needing_review
    resolve_all.select(&:needs_review)
  end

  def resolutions_resolved
    resolve_all.reject(&:needs_review)
  end

  def create_alias_from_user_choice(raw_name, merchant)
    return nil unless merchant && raw_name.present?

    @family.merchant_aliases.find_or_create_by(
      normalized_name: MerchantNameNormalizer.normalize(raw_name)
    ) do |alias_record|
      alias_record.raw_name = raw_name
      alias_record.merchant = merchant
      alias_record.source = "user_resolution"
    end
  end
end
