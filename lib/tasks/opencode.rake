namespace :opencode do
  namespace :config do
    desc "Generate opencode.json for hybrid dev setup"
    task generate: :environment do
      config = OpencodeConfigGenerator.from_settings
      output_path = Rails.root.join(".opencode", "opencode.json")

      config.write_to(output_path)

      puts "OpenCode config written to: #{output_path}"
      puts "MCP URL: #{config.generate.dig('mcp', 'maybe-finance', 'url')}"
      puts "Providers: #{config.generate['provider'].keys.join(', ') || '(none)'}"
    end
  end
end
