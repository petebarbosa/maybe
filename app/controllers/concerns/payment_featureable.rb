module PaymentFeatureable
  extend ActiveSupport::Concern

  included do
    helper_method :payments_enabled?, :payments_disabled?
  end

  private
    def payments_enabled?
      Rails.application.config.x.features.payments_enabled
    end

    def payments_disabled?
      !payments_enabled?
    end
end
