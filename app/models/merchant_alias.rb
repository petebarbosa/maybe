class MerchantAlias < ApplicationRecord
  belongs_to :family
  belongs_to :merchant

  SOURCES = %w[user_manual user_resolution import_learned].freeze

  validates :raw_name, presence: true
  validates :normalized_name, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :normalized_name, uniqueness: { scope: :family_id }

  before_validation :normalize_name

  private

    def normalize_name
      self.normalized_name = MerchantNameNormalizer.normalize(raw_name) if raw_name.present?
    end
end
