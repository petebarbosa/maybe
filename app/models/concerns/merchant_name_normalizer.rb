module MerchantNameNormalizer
  def self.normalize(name)
    return "" if name.blank?

    name.to_s
        .upcase
        .gsub(/'/, "")
        .unicode_normalize(:nfkd)
        .gsub(/[\u0300-\u036f]/, "")
        .gsub(/[^\p{Alnum}\s]/, " ")
        .gsub(/\s+/, " ")
        .strip
  end
end
