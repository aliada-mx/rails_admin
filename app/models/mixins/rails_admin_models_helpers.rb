module Mixins
  module RailsAdminModelsHelpers
    def rails_admin_edit_link(object)
      return '' if object.blank?

      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(object.class, object, host: host)
      name = object.name || object.title || object.id

      ActionController::Base.helpers.link_to(name, url)
    end
  end
end
