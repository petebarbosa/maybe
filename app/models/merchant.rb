class Merchant < ApplicationRecord
  TYPES = %w[FamilyMerchant ProviderMerchant].freeze

  has_many :transactions, dependent: :nullify

  validates :name, presence: true
  validates :type, inclusion: { in: TYPES }

  has_many :aliases, class_name: "MerchantAlias", dependent: :destroy

  scope :alphabetically, -> { order(:name) }
end
