class ApplicationController < ActionController::Base
  include AliadaSupport::RedirectAfterLogin

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Exception raised by conekta
  rescue_from Conekta::Error do |exception|
    render json: { status: :error, sender: :conekta, messages: [exception.message_to_purchaser]}
  end

  # Force signing in if the user does not have permission
  # to see the admin
  rescue_from CanCan::AccessDenied do |exception|
    store_destination

    !user_signed_in? && redirect_to_login || default_redirect_root_path
  end

  def initialize_js_variables
    @conekta_public_key = Rails.application.secrets.conekta_public_key.html_safe
  end

  private
    def current_ability
      @current_ability ||= Ability.new(current_user, params)
    end
end
