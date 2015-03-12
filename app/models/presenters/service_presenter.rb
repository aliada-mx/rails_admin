module Presenters
  include ApplicationHelper

  module ServicePresenter
    def status_enum
      Service::STATUSES
    end

    def user_link
      host = Rails.configuration.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(user.class, user, host: host)
      name = "(#{user.id}) #{ user.name }"

      ActionController::Base.helpers.link_to(name, url)
    end
  end
end
