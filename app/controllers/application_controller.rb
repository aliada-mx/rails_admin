class ApplicationController < ActionController::Base
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

  def after_sign_in_path_for(resource)
    next_url = session['next_url']

    if next_url.present? && next_url != request.url
      clear_stored_destination
      next_url
    else
      next_services_users_path(resource.id)
    end
  end

  def redirect_to_login
    redirect_to Rails.application.routes.url_helpers.new_user_session_path, flash: {message: t('devise.sessions.sign_in_required')}
  end

  def default_redirect_root_path
    redirect_to main_app.root_url, alert: t('devise.sessions.permission_denied')
  end

  def store_destination
    session['next_url'] = request.url
  end

  def clear_stored_destination
    session['next_url'] = nil
  end

  private
    def current_ability
      @current_ability ||= Ability.new(current_user, params)
    end
end
