class Provider::Opencode::ChatResponseParser
  def initialize(raw_response)
    @raw_response = raw_response
  end

  def parsed
    ChatResponse.new(
      id: message_id,
      model: model_string,
      messages: text_messages,
      function_requests: function_requests
    )
  end

  private
    attr_reader :raw_response

    ChatResponse = Provider::LlmConcept::ChatResponse
    ChatMessage = Provider::LlmConcept::ChatMessage
    ChatFunctionRequest = Provider::LlmConcept::ChatFunctionRequest

    def info
      raw_response["info"] || {}
    end

    def parts
      raw_response["parts"] || []
    end

    def message_id
      info["id"]
    end

    def model_string
      model = info["model"]
      return nil unless model.is_a?(Hash)
      "#{model['providerID']}/#{model['modelID']}"
    end

    def text_parts
      parts.select { |p| p["type"] == "text" }
    end

    def tool_invocation_parts
      parts.select { |p| p["type"] == "tool-invocations" }
    end

    def text_messages
      return [] if text_parts.empty?

      combined_text = text_parts.map { |p| p["content"] }.join
      [
        ChatMessage.new(
          id: message_id,
          output_text: combined_text
        )
      ]
    end

    def function_requests
      tool_invocation_parts.filter_map do |part|
        invocation = part["toolInvocation"]
        next unless invocation && invocation["state"] == "call"

        ChatFunctionRequest.new(
          id: invocation["toolCallId"],
          call_id: invocation["toolCallId"],
          function_name: invocation["toolName"],
          function_args: invocation["args"].to_json
        )
      end
    end
end
