require "test_helper"

class MerchantAliasTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @merchant = Merchant.create!(name: "Test Merchant", type: "FamilyMerchant", family: @family)
  end

  test "should be valid" do
    alias_record = MerchantAlias.new(
      family: @family,
      merchant: @merchant,
      raw_name: "plvaa plval"
    )
    assert alias_record.valid?
    assert_equal "PLVAA PLVAL", alias_record.normalized_name
  end

  test "should require raw_name" do
    alias_record = MerchantAlias.new(
      family: @family,
      merchant: @merchant,
      raw_name: nil
    )
    assert_not alias_record.valid?
    assert_includes alias_record.errors[:raw_name], "can't be blank"
  end

  test "should require merchant" do
    alias_record = MerchantAlias.new(
      family: @family,
      raw_name: "PLVAA PLVAL"
    )
    assert_not alias_record.valid?
    assert_includes alias_record.errors[:merchant], "must exist"
  end

  test "should require family" do
    alias_record = MerchantAlias.new(
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )
    assert_not alias_record.valid?
    assert_includes alias_record.errors[:family], "must exist"
  end

  test "should validate source inclusion" do
    alias_record = MerchantAlias.new(
      family: @family,
      merchant: @merchant,
      raw_name: "Test",
      source: "invalid_source"
    )
    assert_not alias_record.valid?
    assert_includes alias_record.errors[:source], "is not included in the list"
  end

  test "should not allow duplicate normalized names per family" do
    MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )

    duplicate = MerchantAlias.new(
      family: @family,
      merchant: @merchant,
      raw_name: "plvaa plval"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized_name], "has already been taken"
  end

  test "should allow same normalized name across different families" do
    other_family = Family.create!(locale: "en", date_format: "%Y-%m-%d")
    other_merchant = Merchant.create!(name: "Other Merchant", type: "FamilyMerchant", family: other_family)

    MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )

    other_alias = MerchantAlias.new(
      family: other_family,
      merchant: other_merchant,
      raw_name: "PLVAA PLVAL"
    )
    assert other_alias.valid?
  end

  test "should destroy aliases when merchant is destroyed" do
    alias_record = MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )

    @merchant.destroy
    assert_not MerchantAlias.exists?(alias_record.id)
  end

  test "merchant alias association has dependent destroy for merchant" do
    reflection = Merchant.reflect_on_association(:aliases)
    assert_equal :destroy, reflection.options[:dependent]
  end

  test "merchant alias association has dependent destroy for family" do
    reflection = Family.reflect_on_association(:merchant_aliases)
    assert_equal :destroy, reflection.options[:dependent]
  end
end
