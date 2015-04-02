module Mixins
  module RailsAdminModelsHelpers
    def rails_admin_edit_link(object, name: nil)
      return '' if object.blank?

      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(object.class, object, host: host)
      name = name || object.name || object.title || object.id

      ActionController::Base.helpers.link_to(name, url)
    end

    def address_map_action_link(address, name: nil)
      return '' if address.blank?

      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.address_map_path('Address', address.id)
      name = name || address.name || address.title || address.id

      ActionController::Base.helpers.link_to(name, url)
    end
  end
end
