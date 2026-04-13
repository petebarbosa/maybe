module McpTools
  class ConfirmAction
    include Base

    def self.tool_name
      "confirm_action"
    end

    def self.tool_description
      "Confirm and execute a previously prepared action. Use this after the user has reviewed and approved the preview from a prepare_* tool. Requires the pending_action_id from the prepare response."
    end

    def self.tool_input_schema
      {
        type: "object",
        properties: {
          pending_action_id: {
            type: "string",
            format: "uuid",
            description: "The ID of the pending action to confirm"
          }
        },
        required: [ "pending_action_id" ]
      }
    end

    def self.execute(params)
      id = params["pending_action_id"]
      action = PendingAction.confirm_and_execute!(id: id, confirmed_by: "mcp")

      unless action
        return {
          content: [ { type: "text", text: "Action not found, already confirmed, or expired." } ]
        }
      end

      result = action.audit_result
      status_text = result["success"] ? "SUCCESS" : "FAILED"

      {
        content: [
          { type: "text", text: "Action #{status_text}: #{action.action_type}\nResult: #{result.to_json}" }
        ]
      }
    end
  end
end
