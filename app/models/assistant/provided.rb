module Assistant::Provided
  extend ActiveSupport::Concern

  def get_model_provider(_ai_model)
    registry.providers.first
  end

  private
    def registry
      @registry ||= Provider::Registry.for_concept(:llm)
    end
end
