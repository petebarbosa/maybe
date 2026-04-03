class Settings::HostingsController < ApplicationController
  layout "settings"

  guard_feature unless: -> { self_hosted? }

  before_action :ensure_admin, only: :clear_cache

  def show
    synth_provider = Provider::Registry.get_provider(:synth)
    @synth_usage = synth_provider&.usage

    load_ai_settings
  end

  def update
    if hosting_params.key?(:require_invite_for_signup)
      Setting.require_invite_for_signup = hosting_params[:require_invite_for_signup]
    end

    if hosting_params.key?(:require_email_confirmation)
      Setting.require_email_confirmation = hosting_params[:require_email_confirmation]
    end

    if hosting_params.key?(:synth_api_key)
      Setting.synth_api_key = hosting_params[:synth_api_key]
    end

    if hosting_params.key?(:opencode_default_model)
      Setting.opencode_default_model = hosting_params[:opencode_default_model]
    end

    redirect_to settings_hosting_path, notice: t(".success")
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = t(".failure")
    render :show, status: :unprocessable_entity
  end

  def clear_cache
    DataCacheClearJob.perform_later(Current.family)
    redirect_to settings_hosting_path, notice: t(".cache_cleared")
  end

  private
    def hosting_params
      params.require(:setting).permit(
        :require_invite_for_signup,
        :require_email_confirmation,
        :synth_api_key,
        :opencode_default_model
      )
    end

    def ensure_admin
      redirect_to settings_hosting_path, alert: t(".not_authorized") unless Current.user.admin?
    end

    def load_ai_settings
      @ai_connected = false
      @ai_connected_providers = []
      @ai_available_models = []

      client = Provider::Opencode::Client.new(
        base_url: Setting.opencode_server_url,
        password: Setting.opencode_server_password
      )

      provider_data = client.list_providers
      @ai_connected = true
      @ai_connected_providers = provider_data["connected"] || []

      all_providers = provider_data["all"] || []
      @ai_available_models = all_providers
        .select { |p| @ai_connected_providers.include?(p["id"]) }
        .flat_map do |provider|
          (provider["models"] || []).map do |model|
            ["#{provider['name']} / #{model['name']}", "#{provider['id']}/#{model['id']}"]
          end
        end
    rescue Faraday::Error, StandardError
      @ai_connected = false
    end
end
