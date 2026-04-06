require "test_helper"

class MerchantAliasResolutionTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @merchant = Merchant.create!(name: "Plaza Vea", type: "FamilyMerchant", family: @family)

    @alias = MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )
  end

  test "full resolution flow with alias match" do
    resolver = MerchantResolver.new(@family)
    result = resolver.resolve("PLVAA PLVAL")

    assert_equal @merchant, result.merchant
    assert_equal :alias_exact, result.method
    assert_equal 1.0, result.confidence
  end

  test "full resolution flow with normalized match" do
    resolver = MerchantResolver.new(@family)
    result = resolver.resolve("plvaa plval")

    assert_equal @merchant, result.merchant
    assert_equal :alias_exact, result.method
  end

  test "import resolution creates alias on user choice" do
    new_merchant = Merchant.create!(name: "Wong", type: "FamilyMerchant", family: @family)

    resolution = Import::MerchantResolution.new(@family, [])
    alias_record = resolution.create_alias_from_user_choice("WNG STORE 123", new_merchant)

    assert_not_nil alias_record
    assert_equal "WNG STORE 123", alias_record.raw_name
    assert_equal new_merchant, alias_record.merchant
    assert_equal "user_resolution", alias_record.source

    resolver = MerchantResolver.new(@family)
    result = resolver.resolve("WNG STORE 123")
    assert_equal new_merchant, result.merchant
    assert_equal :alias_exact, result.method
  end

  test "multiple aliases for same merchant" do
    MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "Plaza Vea Store"
    )

    resolver = MerchantResolver.new(@family)

    result1 = resolver.resolve("PLVAA PLVAL")
    result2 = resolver.resolve("PLAZA VEA STORE")

    assert_equal @merchant, result1.merchant
    assert_equal @merchant, result2.merchant
  end

  test "alias isolation between families" do
    other_family = Family.create!(locale: "en", date_format: "%Y-%m-%d")
    other_merchant = Merchant.create!(name: "Other Plaza", type: "FamilyMerchant", family: other_family)

    MerchantAlias.create!(
      family: other_family,
      merchant: other_merchant,
      raw_name: "PLVAA PLVAL"
    )

    resolver = MerchantResolver.new(@family)
    other_resolver = MerchantResolver.new(other_family)

    result = resolver.resolve("PLVAA PLVAL")
    other_result = other_resolver.resolve("PLVAA PLVAL")

    assert_equal @merchant, result.merchant
    assert_equal other_merchant, other_result.merchant
  end
end
