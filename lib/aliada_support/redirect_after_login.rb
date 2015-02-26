module AliadaSupport
  module RedirectAfterLogin
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
  end
end
