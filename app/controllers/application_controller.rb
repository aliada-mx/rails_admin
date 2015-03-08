class ApplicationController < ActionController::Base
  include AliadaSupport::RedirectAfterLogin

  before_filter :initialize_js_variables
  before_filter :set_current_timezone

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Exception raised by conekta
  rescue_from Conekta::Error do |exception|
    render json: { status: :warning, sender: :conekta, messages: [exception.message_to_purchaser]}
  end

  # Force signing in if the user does not have permission
  # to see the admin
  rescue_from CanCan::AccessDenied do |exception|
    store_destination

    !user_signed_in? && redirect_to_login || default_redirect_root_path
  end
  
  # We don't want to set Time.zone = 'Mexico City' because internally we 
  # depend on keeping the default UTC
  def set_current_timezone
    @current_timezone ||= ENV['TZ'] || 'Mexico City'
  end

  def initialize_js_variables
    @conekta_public_key = Rails.application.secrets.conekta_public_key.html_safe
  end

  private
    def current_ability
      @current_ability ||= Ability.new(current_user, params)
    end
end
