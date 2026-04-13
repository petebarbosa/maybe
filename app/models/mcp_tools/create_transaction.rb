module McpTools
  class CreateTransaction
    include Base

    def self.tool_name
      "create_transaction"
    end

    def self.tool_description
      "Prepare a new transaction for creation. Returns a preview and pending_action_id for confirmation. Does NOT create the transaction until confirm_action is called."
    end

    def self.tool_input_schema
      {
        type: "object",
        properties: {
          family_id: {
            type: "string",
            format: "uuid",
            description: "The family ID that owns the account"
          },
          account_id: {
            type: "string",
            format: "uuid",
            description: "The account ID for this transaction"
          },
          date: {
            type: "string",
            format: "date",
            description: "Transaction date (YYYY-MM-DD)"
          },
          name: {
            type: "string",
            description: "Transaction description/name"
          },
          amount: {
            type: "string",
            description: "Amount as decimal string. Positive for expense, negative for income"
          },
          currency: {
            type: "string",
            description: "Currency code (defaults to family currency)"
          },
          category_id: {
            type: "string",
            format: "uuid",
            description: "Optional category ID"
          },
          merchant_id: {
            type: "string",
            format: "uuid",
            description: "Optional merchant ID"
          },
          kind: {
            type: "string",
            enum: %w[standard funds_movement cc_payment loan_payment one_time],
            description: "Transaction kind (defaults to standard)"
          }
        },
        required: %w[family_id account_id date name amount]
      }
    end

    def self.execute(params)
      family = resolve_family(params["family_id"])
      account = family.accounts.find(params["account_id"])
      currency = params["currency"] || family.currency
      amount = BigDecimal(params["amount"])
      kind = params["kind"] || "standard"

      preview = {
        action: "create_transaction",
        account_name: account.name,
        date: params["date"],
        name: params["name"],
        amount: amount.to_s,
        currency: currency,
        kind: kind,
        category_id: params["category_id"],
        merchant_id: params["merchant_id"]
      }

      pending = PendingAction.create_pending!(
        action_type: "create_transaction",
        params: params,
        preview: preview,
        family: family
      )

      {
        content: [
          { type: "text", text: "Transaction prepared for review.\nPreview: #{preview.to_json}\n\nCall confirm_action with pending_action_id: #{pending.id} to execute." }
        ]
      }
    rescue ActiveRecord::RecordNotFound => e
      { content: [ { type: "text", text: "Error: #{e.message}" } ] }
    rescue => e
      { content: [ { type: "text", text: "Error: #{e.message}" } ] }
    end
  end
end
