require "test_helper"

class Provider::RegistryTest < ActiveSupport::TestCase
  test "synth configured with ENV" do
    Setting.stubs(:synth_api_key).returns(nil)

    with_env_overrides SYNTH_API_KEY: "123" do
      assert_instance_of Provider::Synth, Provider::Registry.get_provider(:synth)
    end
  end

  test "synth configured with Setting" do
    Setting.stubs(:synth_api_key).returns("123")

    with_env_overrides SYNTH_API_KEY: nil do
      assert_instance_of Provider::Synth, Provider::Registry.get_provider(:synth)
    end
  end

  test "synth not configured" do
    Setting.stubs(:synth_api_key).returns(nil)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_nil Provider::Registry.get_provider(:synth)
    end
  end

  test "composite_exchange_rates returns instance" do
    provider = Provider::Registry.get_provider(:composite_exchange_rates)
    assert_instance_of Provider::CompositeExchangeRates, provider
  end

  test "composite_exchange_rates available providers includes composite" do
    registry = Provider::Registry.for_concept(:exchange_rates)
    assert_includes registry.providers.map(&:class), Provider::CompositeExchangeRates
  end
end
