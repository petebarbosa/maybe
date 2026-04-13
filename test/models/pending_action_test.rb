require "test_helper"

class PendingActionTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @account = @family.accounts.create!(name: "Test account", balance: 1000, currency: "USD", accountable: Depository.new)
  end

  test "creates pending action with valid params" do
    pending = PendingAction.create_pending!(
      action_type: "create_transaction",
      params: { "account_id" => @account.id, "date" => Date.current.to_s, "name" => "Test", "amount" => "10" },
      preview: { action: "create_transaction" },
      family: @family
    )

    assert pending.persisted?
    assert pending.expires_at > Time.current
    refute pending.confirmed?
    assert_nil pending.confirmed_at
  end

  test "expired action cannot be confirmed" do
    pending = PendingAction.create_pending!(
      action_type: "create_transaction",
      params: { "account_id" => @account.id, "date" => Date.current.to_s, "name" => "Test", "amount" => "10" },
      preview: { action: "create_transaction" },
      family: @family
    )

    pending.update!(expires_at: 1.hour.ago)
    result = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert_nil result
  end

  test "already confirmed action cannot be confirmed again" do
    pending = PendingAction.create_pending!(
      action_type: "create_transaction",
      params: { "account_id" => @account.id, "date" => Date.current.to_s, "name" => "Test", "amount" => "10" },
      preview: { action: "create_transaction" },
      family: @family
    )

    first = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")
    assert first.present?

    second = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")
    assert_nil second
  end

  test "execute_create_transaction creates entry and transaction" do
    pending = PendingAction.create_pending!(
      action_type: "create_transaction",
      params: {
        "family_id" => @family.id,
        "account_id" => @account.id,
        "date" => Date.current.to_s,
        "name" => "MCP Test Transaction",
        "amount" => "42.50"
      },
      preview: { action: "create_transaction", amount: "42.50" },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert confirmed.confirmed?
    assert_equal "test", confirmed.confirmed_by
    assert confirmed.audit_result["success"]
    assert confirmed.audit_result["entry_id"].present?
    assert confirmed.audit_result["transaction_id"].present?

    entry = Entry.find(confirmed.audit_result["entry_id"])
    assert_equal "MCP Test Transaction", entry.name
    assert_equal BigDecimal("42.50"), entry.amount
  end

  test "execute_update_transaction updates existing entry" do
    entry = Entry.create!(
      account: @account,
      date: 1.day.ago.to_date,
      name: "Original",
      amount: 100,
      currency: "USD",
      entryable: Transaction.new
    )

    pending = PendingAction.create_pending!(
      action_type: "update_transaction",
      params: {
        "family_id" => @family.id,
        "entry_id" => entry.id,
        "name" => "Updated Name",
        "amount" => "200"
      },
      preview: { action: "update_transaction" },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert confirmed.audit_result["success"]
    entry.reload
    assert_equal "Updated Name", entry.name
    assert_equal BigDecimal("200"), entry.amount
  end

  test "execute_update_transaction rejects entry from different family" do
    other_family = Family.create!(currency: "USD")
    other_account = other_family.accounts.create!(name: "Other", balance: 0, currency: "USD", accountable: Depository.new)
    entry = Entry.create!(
      account: other_account,
      date: Date.current,
      name: "Other family entry",
      amount: 50,
      currency: "USD",
      entryable: Transaction.new
    )

    pending = PendingAction.create_pending!(
      action_type: "update_transaction",
      params: {
        "family_id" => @family.id,
        "entry_id" => entry.id,
        "name" => "Hacked"
      },
      preview: { action: "update_transaction" },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert_equal false, confirmed.audit_result["success"]
  end

  test "execute_create_or_update_budget creates budget" do
    month_param = Budget.date_to_param(Date.current.beginning_of_month)

    pending = PendingAction.create_pending!(
      action_type: "create_or_update_budget",
      params: {
        "family_id" => @family.id,
        "month_year" => month_param,
        "budgeted_spending" => "5000"
      },
      preview: { action: "create_or_update_budget" },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert confirmed.audit_result["success"]
    budget = Budget.find(confirmed.audit_result["budget_id"])
    assert_equal BigDecimal("5000"), budget.budgeted_spending
  end

  test "execute_create_or_update_budget_category creates category allocation" do
    category = @family.categories.first
    month_param = Budget.date_to_param(Date.current.beginning_of_month)

    pending = PendingAction.create_pending!(
      action_type: "create_or_update_budget_category",
      params: {
        "family_id" => @family.id,
        "month_year" => month_param,
        "category_id" => category.id,
        "budgeted_spending" => "500"
      },
      preview: { action: "create_or_update_budget_category" },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert confirmed.audit_result["success"]
  end

  test "execute_upsert_exchange_rates saves rates" do
    pending = PendingAction.create_pending!(
      action_type: "upsert_exchange_rates",
      params: {
        "family_id" => @family.id,
        "rates" => [
          { "from_currency" => "USD", "to_currency" => "EUR", "date" => Date.current.to_s, "rate" => "0.91" }
        ]
      },
      preview: { action: "upsert_exchange_rates", rate_count: 1 },
      family: @family
    )

    confirmed = PendingAction.confirm_and_execute!(id: pending.id, confirmed_by: "test")

    assert confirmed.audit_result["success"]
    assert_equal 1, confirmed.audit_result["upserted"]

    rate = ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR", date: Date.current)
    assert_equal BigDecimal("0.91"), rate.rate
  end

  test "unknown action type raises error" do
    pending = PendingAction.create_pending!(
      action_type: "unknown_action",
      params: { "test" => "value" },
      preview: { action: "unknown" },
      family: @family
    )

    assert_raises(RuntimeError) { pending.execute! }
  end
end
