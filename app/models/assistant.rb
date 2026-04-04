class Assistant
  include Provided, Configurable, Broadcastable

  attr_reader :chat, :instructions

  class << self
    def for_chat(chat)
      config = config_for(chat)
      new(chat, instructions: config[:instructions])
    end
  end

  def initialize(chat, instructions: nil)
    @chat = chat
    @instructions = instructions
  end

  def respond_to(message)
    assistant_message = AssistantMessage.new(
      chat: chat,
      content: "",
      ai_model: message.ai_model
    )

    llm = get_model_provider(message.ai_model)

    streamer = proc do |chunk|
      case chunk.type
      when "output_text"
        if assistant_message.content.blank?
          stop_thinking

          assistant_message.append_text!(chunk.data)
          chat.update_latest_response!(chat.opencode_session_id)
        else
          assistant_message.append_text!(chunk.data)
        end
      when "response"
        chat.update_latest_response!(chunk.data.id)
      end
    end

    session_id = chat.opencode_session_id

    response = llm.chat_response(
      message.content,
      model: message.ai_model,
      instructions: instructions,
      streamer: streamer,
      previous_response_id: session_id
    )

    unless response.success?
      raise response.error
    end

    if chat.opencode_session_id.blank? && response.data&.id.present?
      chat.update!(opencode_session_id: response.data.id)
    end

    response.data
  rescue => e
    stop_thinking
    chat.add_error(e)
  end
end
