class Provider::Opencode::MerchantSuggester
  def initialize(client, raw_name:, normalized_name:, user_merchants:, model: {})
    @client = client
    @raw_name = raw_name
    @normalized_name = normalized_name
    @user_merchants = user_merchants
    @model = model
  end

  def suggest
    session = client.create_session(title: "suggest-merchant")
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
    build_response(structured)
  ensure
    client.delete_session(session_id) if session_id
  end

  private
    attr_reader :client, :raw_name, :normalized_name, :user_merchants, :model

    MerchantSuggestion = Provider::LlmConcept::MerchantSuggestion

    def build_response(structured)
      return nil unless structured

      merchant_id = structured["merchant_id"]
      confidence = structured["confidence"] || 0.0
      rationale = structured["rationale"] || ""

      MerchantSuggestion.new(
        merchant_id: merchant_id,
        confidence: confidence.to_f,
        rationale: rationale
      )
    rescue
      nil
    end

    def json_schema
      {
        type: "object",
        properties: {
          merchant_id: {
            type: %w[string null],
            description: "The ID of the suggested merchant, or null if uncertain"
          },
          confidence: {
            type: "number",
            description: "Confidence score between 0.0 and 1.0"
          },
          rationale: {
            type: "string",
            description: "Brief explanation of why this merchant was suggested"
          }
        },
        required: %w[merchant_id confidence rationale],
        additionalProperties: false
      }
    end

    def developer_message
      <<~MESSAGE.strip
        Raw transaction descriptor: #{raw_name}
        Normalized: #{normalized_name}

        Available merchants:
        #{user_merchants.to_json}

        Suggest the best matching merchant from the list above, or null if uncertain.
        Return confidence between 0.0 and 1.0.
      MESSAGE
    end

    def instructions
      <<~INSTRUCTIONS.strip
        You are an assistant to a consumer personal finance app.

        Match the transaction descriptor to one of the user's merchants.

        Rules:
        - Return merchant_id from the provided list, or null
        - Be conservative: return null if confidence is below 0.6
        - Consider abbreviations, typos, and common variations
        - Never invent a merchant not in the user's list
        - Provide brief rationale for your choice
      INSTRUCTIONS
    end
end
