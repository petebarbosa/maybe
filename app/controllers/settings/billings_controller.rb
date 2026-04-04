class Settings::BillingsController < ApplicationController
  layout "settings"

  before_action :redirect_if_payments_disabled

  def show
    @family = Current.family
  end

  private
    def redirect_if_payments_disabled
      redirect_to root_path if payments_disabled?
    end
end
