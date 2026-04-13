class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, if: -> { defined?(super) }
  before_action :authenticate_mcp_client

  def handle
    server = MCP::Server.new(
      name: "maybe-finance",
      version: "1.0.0",
      tools: [
        McpTools::GetTransactions,
        McpTools::GetAccounts,
        McpTools::GetBalanceSheet,
        McpTools::GetIncomeStatement,
        McpTools::ConfirmAction,
        McpTools::CreateTransaction,
        McpTools::UpdateTransaction,
        McpTools::CreateOrUpdateBudget,
        McpTools::CreateOrUpdateBudgetCategory,
        McpTools::UpsertExchangeRates
      ]
    )

    result = server.handle_json(request.body.read)
    render json: result
  end

  private

    def authenticate_mcp_client
      token = extract_bearer_token
      expected = Setting.mcp_auth_token

      unless expected.present? && token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    def extract_bearer_token
      header = request.headers["Authorization"]
      return nil unless header&.start_with?("Bearer ")
      header.sub("Bearer ", "")
    end
end
