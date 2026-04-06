require "test_helper"

class MerchantNameNormalizerTest < ActiveSupport::TestCase
  test "normalizes basic merchant name" do
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("Plaza Vea")
  end

  test "normalizes lowercase name" do
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("plaza vea")
  end

  test "removes diacritics" do
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("pláza veá")
  end

  test "removes punctuation" do
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("Plaza-Vea")
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("Plaza.Vea")
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("Plaza, Vea")
  end

  test "collapses multiple spaces" do
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("PLAZA   VEA")
    assert_equal "PLAZA VEA", MerchantNameNormalizer.normalize("  PLAZA   VEA  ")
  end

  test "handles cryptic statement names" do
    assert_equal "PLVAA PLVAL", MerchantNameNormalizer.normalize("PLVAA PLVAL")
    assert_equal "PLVAA PLVAL", MerchantNameNormalizer.normalize("plvaa plval")
    assert_equal "PLVAA PLVAL", MerchantNameNormalizer.normalize("Plvaa Plval")
  end

  test "handles empty and nil input" do
    assert_equal "", MerchantNameNormalizer.normalize("")
    assert_equal "", MerchantNameNormalizer.normalize(nil)
    assert_equal "", MerchantNameNormalizer.normalize("   ")
  end

  test "handles special characters" do
    assert_equal "MCDONALDS 12345", MerchantNameNormalizer.normalize("McDonald's #12345")
    assert_equal "STARBUCKS STORE 001", MerchantNameNormalizer.normalize("Starbucks Store #001")
  end

  test "handles accented characters from various languages" do
    assert_equal "CANTEEN", MerchantNameNormalizer.normalize("CANTÉEN")
    assert_equal "MUNCHEN BAKERY", MerchantNameNormalizer.normalize("München Bakery")
  end
end
