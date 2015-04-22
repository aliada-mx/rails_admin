# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  include AliadaSupport::RedirectAfterLogin
  include ApplicationHelper

  before_filter :initialize_js_variables
  before_filter :set_default_user

  before_filter :set_admin_timezone


  def set_admin_timezone
    return if Rails.env == 'test'

    if in_admin_controller?
      if params[:action] == 'edit' && request.method == 'POST'
        model_name = params[:model_name]

        params[model_name][:in_rails_admin] = true
      end

      if in_dst?
        Time.zone = "Etc/GMT+6"

      else
        Time.zone = "Mexico City"
      end
    else
      Time.zone = "UTC"
    end
  end
   
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from AliadaExceptions::AvailabilityNotFound do |exception|
    Raygun.track_exception(exception, custom_data: exception)
    render json: { status: :error, code: :availability_not_found, message: 'Lo sentimos no encontramos disponibilidad :('}
  end

  rescue_from AliadaExceptions::ServiceDowgradeImpossible do |exception|
    Raygun.track_exception(exception)
    render json: { status: :error, code: :downgrade_impossible, message: 'Lo sentimos no podemos cambiar a ese tipo de servicio :('}
  end

  # Exception raised by conekta
  rescue_from Conekta::Error do |exception|
    render json: { status: :error, sender: :conekta, messages: [exception.message_to_purchaser]}
  end

  rescue_from ActiveRecord::RecordInvalid do |invalid|
    Raygun.track_exception(invalid)
    render json: { status: :error, code: :invalid, message: invalid.message }
  end
   
  # Force signing in if the user does not have permission
  # to see the admin
  rescue_from CanCan::AccessDenied do |exception|
    store_destination

    !user_signed_in? && redirect_to_login || default_redirect_root_path
  end

  def set_default_user
    @user = current_user if user_signed_in?
  end
  
  def initialize_js_variables
    @conekta_public_key = Rails.application.secrets.conekta_public_key.html_safe
    @too_late_cancelation_fee = Setting.too_late_cancelation_fee
  end

  private
    def current_ability
      @current_ability ||= Ability.new(current_user, params)
    end

    def force_sign_in_user(user)
      sign_in(:user, user, { :bypass => true })
    end
end
