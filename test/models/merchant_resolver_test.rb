require "test_helper"

class MerchantResolverTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @merchant = merchants(:netflix)
    @resolver = MerchantResolver.new(@family)
  end

  test "resolves via exact alias match" do
    result = @resolver.resolve("PLVAA PLVAL STORE")
    assert_equal @merchant, result.merchant
    assert_equal :alias_exact, result.method
    assert_equal 1.0, result.confidence
  end

  test "resolves via normalized alias match" do
    result = @resolver.resolve("plvaa plval store")
    assert_equal @merchant, result.merchant
    assert_equal :alias_exact, result.method
  end

  test "returns needs_user_resolution when no alias and no AI" do
    result = @resolver.resolve("UNKNOWN MERCHANT")
    assert_nil result.merchant
    assert_equal :needs_user_resolution, result.method
    assert_equal 0.0, result.confidence
  end

  test "returns no_match for empty input" do
    result = @resolver.resolve("")
    assert_nil result.merchant
    assert_equal :no_match, result.method
  end

  test "returns no_match for nil input" do
    result = @resolver.resolve(nil)
    assert_nil result.merchant
    assert_equal :no_match, result.method
  end
end
