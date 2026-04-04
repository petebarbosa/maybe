require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mcp_token = "test-mcp-token-12345"
    Setting.stubs(:mcp_auth_token).returns(@mcp_token)
  end

  test "handles MCP initialize request" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2025-06-18",
          capabilities: {},
          clientInfo: { name: "test", version: "1.0" }
        }
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@mcp_token}"
      }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert body.dig("result", "serverInfo", "name").present?
  end

  test "handles MCP tools/list request" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 2,
        method: "tools/list",
        params: {}
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@mcp_token}"
      }

    assert_response :success
    body = JSON.parse(response.body)
    tool_names = body.dig("result", "tools").map { |t| t["name"] }
    assert_includes tool_names, "get_transactions"
    assert_includes tool_names, "get_accounts"
    assert_includes tool_names, "get_balance_sheet"
    assert_includes tool_names, "get_income_statement"
  end

  test "rejects unauthenticated requests" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {}
      }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "rejects invalid token" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {}
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer wrong-token"
      }

    assert_response :unauthorized
  end
end
