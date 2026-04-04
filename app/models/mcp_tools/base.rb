module McpTools
  module Base
    def self.resolve_family(family_id)
      Family.find(family_id)
    rescue ActiveRecord::RecordNotFound
      raise ArgumentError, "Family not found: #{family_id}"
    end
  end
end
