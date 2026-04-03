require "test_helper"

class OpencodeConfigGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = OpencodeConfigGenerator.new(
      mcp_url: "http://web:3000/mcp",
      mcp_auth_token: "test-token-123",
      provider_keys: {
        "anthropic" => "sk-ant-test",
        "openai" => "sk-test"
      }
    )
  end

  test "generates valid config hash" do
    config = @generator.generate

    assert config.is_a?(Hash)
    assert config.key?("provider")
    assert config.key?("mcp")
  end

  test "includes provider API keys" do
    config = @generator.generate

    assert_equal "sk-ant-test", config.dig("provider", "anthropic", "api_key")
    assert_equal "sk-test", config.dig("provider", "openai", "api_key")
  end

  test "includes MCP server config" do
    config = @generator.generate

    mcp_config = config.dig("mcp", "maybe-finance")
    assert_equal "remote", mcp_config["type"]
    assert_equal "http://web:3000/mcp", mcp_config["url"]
    assert_equal "Bearer test-token-123", mcp_config.dig("headers", "Authorization")
  end

  test "excludes providers with blank keys" do
    generator = OpencodeConfigGenerator.new(
      mcp_url: "http://web:3000/mcp",
      mcp_auth_token: "test-token",
      provider_keys: {
        "anthropic" => "sk-ant-test",
        "openai" => "",
        "google" => nil
      }
    )

    config = generator.generate

    assert config.dig("provider").key?("anthropic")
    refute config.dig("provider").key?("openai")
    refute config.dig("provider").key?("google")
  end

  test "to_json returns valid JSON string" do
    json = @generator.to_json

    assert json.is_a?(String)
    parsed = JSON.parse(json)
    assert parsed.key?("provider")
  end

  test "write_to writes config to file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "opencode.json")
      @generator.write_to(path)

      assert File.exist?(path)
      parsed = JSON.parse(File.read(path))
      assert_equal "sk-ant-test", parsed.dig("provider", "anthropic", "api_key")
    end
  end
end
