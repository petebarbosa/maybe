module McpTools
  class UpsertExchangeRates
    include Base

    def self.tool_name
      "upsert_exchange_rates"
    end

    def self.tool_description
      "Prepare upsert of exchange rates for one or more currency pairs on specific dates. Returns preview and pending_action_id. Does NOT save until confirm_action is called."
    end

    def self.tool_input_schema
      {
        type: "object",
        properties: {
          family_id: {
            type: "string",
            format: "uuid",
            description: "The family ID"
          },
          rates: {
            type: "array",
            description: "Array of rate objects to upsert",
            items: {
              type: "object",
              properties: {
                from_currency: {
                  type: "string",
                  description: "Source currency ISO code (e.g., USD)"
                },
                to_currency: {
                  type: "string",
                  description: "Target currency ISO code (e.g., EUR)"
                },
                date: {
                  type: "string",
                  format: "date",
                  description: "Rate date (YYYY-MM-DD)"
                },
                rate: {
                  type: "string",
                  description: "Exchange rate as decimal string"
                },
                source_url: {
                  type: "string",
                  description: "Optional source URL for audit"
                },
                source_name: {
                  type: "string",
                  description: "Optional source name (e.g., ECB, Kraken)"
                }
              },
              required: %w[from_currency to_currency date rate]
            }
          }
        },
        required: %w[family_id rates]
      }
    end

    def self.execute(params)
      family = resolve_family(params["family_id"])
      rates = params["rates"]

      unless rates.is_a?(Array) && rates.any?
        return { content: [ { type: "text", text: "Error: rates array is required and must not be empty." } ] }
      end

      preview = {
        action: "upsert_exchange_rates",
        rate_count: rates.size,
        sample: rates.first(3).map { |r| "#{r["from_currency"]}/#{r["to_currency"]} on #{r["date"]}: #{r["rate"]}" }
      }

      pending = PendingAction.create_pending!(
        action_type: "upsert_exchange_rates",
        params: params,
        preview: preview,
        family: family
      )

      {
        content: [
          { type: "text", text: "Exchange rate upsert prepared.\nPreview: #{preview.to_json}\n\nCall confirm_action with pending_action_id: #{pending.id} to execute." }
        ]
      }
    rescue => e
      { content: [ { type: "text", text: "Error: #{e.message}" } ] }
    end
  end
end
