class PendingAction < ApplicationRecord
  belongs_to :family

  validates :action_type, presence: true
  validates :params, :preview, :expires_at, presence: true
  validate :preview_not_empty

  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :pending, -> { not_expired.where(confirmed_at: nil) }

  TTL = 10.minutes

  class << self
    def create_pending!(action_type:, params:, preview:, family:)
      create!(
        action_type: action_type,
        params: params,
        preview: preview,
        family: family,
        expires_at: TTL.from_now
      )
    end

    def confirm_and_execute!(id:, confirmed_by: nil)
      action = pending.find_by(id: id)
      return nil unless action

      result = action.execute!
      action.update!(
        confirmed_at: Time.current,
        confirmed_by: confirmed_by,
        audit_result: result
      )
      action
    end
  end

  def expired?
    expires_at <= Time.current
  end

  def confirmed?
    confirmed_at.present?
  end

  def execute!
    raise "Already confirmed" if confirmed?
    raise "Expired" if expired?

    case action_type
    when "create_transaction"
      execute_create_transaction
    when "update_transaction"
      execute_update_transaction
    when "create_or_update_budget"
      execute_create_or_update_budget
    when "create_or_update_budget_category"
      execute_create_or_update_budget_category
    when "upsert_exchange_rates"
      execute_upsert_exchange_rates
    else
      raise "Unknown action type: #{action_type}"
    end
  end

  private

    def preview_not_empty
      errors.add(:preview, "must not be empty") if preview.is_a?(Hash) && preview.empty?
    end

    def execute_create_transaction
      account = family.accounts.find(params["account_id"])
      entry = Entry.create!(
        account: account,
        date: Date.parse(params["date"]),
        name: params["name"],
        amount: BigDecimal(params["amount"]),
        currency: params["currency"] || family.currency,
        entryable: Transaction.new(
          category_id: params["category_id"],
          merchant_id: params["merchant_id"],
          kind: params["kind"] || "standard"
        )
      )
      { success: true, entry_id: entry.id, transaction_id: entry.entryable_id }
    rescue => e
      { success: false, error: e.message }
    end

    def execute_update_transaction
      entry = Entry.find(params["entry_id"])
      raise "Entry does not belong to family" unless entry.account.family_id == family.id

      update_attrs = {
        date: params["date"] ? Date.parse(params["date"]) : nil,
        name: params["name"],
        amount: params["amount"] ? BigDecimal(params["amount"]) : nil,
        currency: params["currency"]
      }.compact_blank

      transaction_attrs = {
        category_id: params["category_id"],
        merchant_id: params["merchant_id"],
        kind: params["kind"]
      }.compact_blank

      entry.update!(update_attrs) if update_attrs.any?
      entry.entryable.update!(transaction_attrs) if transaction_attrs.any?

      { success: true, entry_id: entry.id }
    rescue => e
      { success: false, error: e.message }
    end

    def execute_create_or_update_budget
      month_date = Budget.param_to_date(params["month_year"])
      budget = Budget.find_or_bootstrap(family, start_date: month_date)
      return { success: false, error: "Invalid budget date" } unless budget

      if params.key?("budgeted_spending")
        budget.update!(budgeted_spending: BigDecimal(params["budgeted_spending"]))
      end

      { success: true, budget_id: budget.id, month: budget.name }
    rescue => e
      { success: false, error: e.message }
    end

    def execute_create_or_update_budget_category
      month_date = Budget.param_to_date(params["month_year"])
      budget = Budget.find_or_bootstrap(family, start_date: month_date)
      return { success: false, error: "Invalid budget date" } unless budget

      budget_category = budget.budget_categories.find_or_initialize_by(
        category_id: params["category_id"]
      )
      budget_category.update!(
        budgeted_spending: BigDecimal(params["budgeted_spending"])
      )

      { success: true, budget_category_id: budget_category.id, category_name: budget_category.category.name }
    rescue => e
      { success: false, error: e.message }
    end

    def execute_upsert_exchange_rates
      rates = params["rates"]
      return { success: false, error: "No rates provided" } unless rates.is_a?(Array) && rates.any?

      upserted = 0
      errors = []

      rates.each do |rate_params|
        rate = ExchangeRate.find_or_initialize_by(
          from_currency: rate_params["from_currency"],
          to_currency: rate_params["to_currency"],
          date: Date.parse(rate_params["date"])
        )
        rate.rate = BigDecimal(rate_params["rate"])
        if rate.save
          upserted += 1
        else
          errors << "#{rate_params["from_currency"]}/#{rate_params["to_currency"]} on #{rate_params["date"]}: #{rate.errors.full_messages.join(", ")}"
        end
      end

      { success: true, upserted: upserted, errors: errors }
    rescue => e
      { success: false, error: e.message }
    end
end
