require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @chat = chats(:two)
    @message = @chat.messages.create!(
      type: "UserMessage",
      content: "What is my net worth?",
      ai_model: "opencode/minimax-m2.5-free"
    )
    @assistant = Assistant.for_chat(@chat)
    @provider = mock
  end

  test "errors get added to chat" do
    @assistant.expects(:get_model_provider).with("opencode/minimax-m2.5-free").returns(@provider)

    error = StandardError.new("test error")
    @provider.expects(:chat_response).returns(provider_error_response(error))

    @chat.expects(:add_error).with(error).once

    assert_no_difference "AssistantMessage.count" do
      @assistant.respond_to(@message)
    end
  end

  test "responds to basic prompt" do
    @assistant.expects(:get_model_provider).with("opencode/minimax-m2.5-free").returns(@provider)

    text_chunk = provider_text_chunk("Your net worth is $50,000.")
    response_data = Provider::LlmConcept::ChatResponse.new(
      id: "msg_1",
      model: "opencode/minimax-m2.5-free",
      messages: [provider_message(id: "msg_1", text: "Your net worth is $50,000.")],
      function_requests: []
    )
    response_chunk = Provider::LlmConcept::ChatStreamChunk.new(type: "response", data: response_data)

    response = provider_success_response(response_data)

    @provider.expects(:chat_response).with do |message, **options|
      options[:streamer].call(text_chunk)
      options[:streamer].call(response_chunk)
      true
    end.returns(response)

    assert_difference "AssistantMessage.count", 1 do
      @assistant.respond_to(@message)
      message = @chat.messages.ordered.where(type: "AssistantMessage").last
      assert_equal "Your net worth is $50,000.", message.content
    end
  end

  private
    def provider_message(id:, text:)
      Provider::LlmConcept::ChatMessage.new(id: id, output_text: text)
    end

    def provider_text_chunk(text)
      Provider::LlmConcept::ChatStreamChunk.new(type: "output_text", data: text)
    end
end
