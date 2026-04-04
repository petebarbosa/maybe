class Provider::Opencode::AutoMerchantDetector
  def initialize(client, transactions:, user_merchants:, model: {})
    @client = client
    @transactions = transactions
    @user_merchants = user_merchants
    @model = model
  end

  def auto_detect_merchants
    session = client.create_session(title: "auto-detect-merchants")
    session_id = session["id"]

    response = client.send_message(session_id,
      content: developer_message,
      model: model,
      system: instructions,
      format: {
        type: "json_schema",
        schema: json_schema
      }
    )

    structured = response.dig("info", "structured_output")
    merchants = structured&.dig("merchants") || []

    build_response(merchants)
  ensure
    client.delete_session(session_id) if session_id
  end

  private
    attr_reader :client, :transactions, :user_merchants, :model

    AutoDetectedMerchant = Provider::LlmConcept::AutoDetectedMerchant

    def build_response(merchants)
      merchants.map do |merchant|
        AutoDetectedMerchant.new(
          transaction_id: merchant["transaction_id"],
          business_name: normalize_value(merchant["business_name"]),
          business_url: normalize_value(merchant["business_url"])
        )
      end
    end

    def normalize_value(value)
      return nil if value == "null"
      value
    end

    def json_schema
      {
        type: "object",
        properties: {
          merchants: {
            type: "array",
            description: "An array of auto-detected merchant businesses for each transaction",
            items: {
              type: "object",
              properties: {
                transaction_id: {
                  type: "string",
                  description: "The internal ID of the original transaction",
                  enum: transactions.map { |t| t[:id] }
                },
                business_name: {
                  type: %w[string null],
                  description: "The detected business name, or null if uncertain"
                },
                business_url: {
                  type: %w[string null],
                  description: "The URL of the detected business, or null if uncertain"
                }
              },
              required: %w[transaction_id business_name business_url],
              additionalProperties: false
            }
          }
        },
        required: %w[merchants],
        additionalProperties: false
      }
    end

    def developer_message
      <<~MESSAGE.strip
        Here are the user's available merchants in JSON format:

        ```json
        #{user_merchants.to_json}
        ```

        Use BOTH your knowledge AND the user-generated merchants to auto-detect the following transactions:

        ```json
        #{transactions.to_json}
        ```

        Return "null" if you are not 80%+ confident in your answer.
      MESSAGE
    end

    def instructions
      <<~INSTRUCTIONS.strip
        You are an assistant to a consumer personal finance app.

        Closely follow ALL the rules below while auto-detecting business names and website URLs:

        - Return 1 result per transaction
        - Correlate each transaction by ID (transaction_id)
        - Do not include the subdomain in the business_url (i.e. "amazon.com" not "www.amazon.com")
        - User merchants are considered "manual" user-generated merchants and should only be used in 100% clear cases
        - Be slightly pessimistic. We favor returning "null" over returning a false positive.
        - NEVER return a name or URL for generic transaction names (e.g. "Paycheck", "Laundromat", "Grocery store", "Local diner")

        Determining a value:

        - First attempt to determine the name + URL from your knowledge of global businesses
        - If no certain match, attempt to match one of the user-provided merchants
        - If no match, return "null"
      INSTRUCTIONS
    end
end
