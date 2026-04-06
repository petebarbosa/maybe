require "test_helper"

class Import::MerchantResolutionTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @merchant = Merchant.create!(name: "Plaza Vea", type: "FamilyMerchant", family: @family)

    MerchantAlias.create!(
      family: @family,
      merchant: @merchant,
      raw_name: "PLVAA PLVAL"
    )

    @transactions = [
      { merchant_descriptor: "PLVAA PLVAL", amount: 100 },
      { merchant_descriptor: "UNKNOWN STORE", amount: 50 },
      { merchant_descriptor: nil, amount: 25 }
    ]

    @resolution = Import::MerchantResolution.new(@family, @transactions)
  end

  test "resolves known aliases" do
    results = @resolution.resolve_all
    assert_equal 3, results.length

    first = results[0]
    assert_equal @merchant, first.merchant
    assert_equal :alias_exact, first.method
    assert_not first.needs_review
  end

  test "marks unknown merchants for review" do
    results = @resolution.resolve_all

    unknown = results[1]
    assert_nil unknown.merchant
    assert unknown.needs_review

    no_descriptor = results[2]
    assert_nil no_descriptor.merchant
    assert no_descriptor.needs_review
  end

  test "filters resolutions needing review" do
    needing_review = @resolution.resolutions_needing_review
    assert_equal 2, needing_review.length
    needing_review.each do |r|
      assert r.needs_review, "should need review"
    end
  end

  test "filters resolved resolutions" do
    resolved = @resolution.resolutions_resolved
    assert_equal 1, resolved.length
    assert_equal @merchant, resolved[0].merchant
  end

  test "creates alias from user choice" do
    new_merchant = Merchant.create!(name: "Wong", type: "FamilyMerchant", family: @family)

    alias_record = @resolution.create_alias_from_user_choice("NEW MERCH DESC", new_merchant)

    assert_not_nil alias_record
    assert_equal "NEW MERCH DESC", alias_record.raw_name
    assert_equal "NEW MERCH DESC", alias_record.normalized_name
    assert_equal new_merchant, alias_record.merchant
    assert_equal "user_resolution", alias_record.source
  end

  test "finds existing alias when creating from user choice" do
    existing = @family.merchant_aliases.find_by(normalized_name: "PLVAA PLVAL")

    result = @resolution.create_alias_from_user_choice("plvaa plval", @merchant)

    assert_equal existing, result
    assert_equal 1, @family.merchant_aliases.where(merchant: @merchant).count
  end
end
