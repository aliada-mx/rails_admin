require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class AddressMap < RailsAdmin::Config::Actions::Base

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :link_icon do
          # Escoger uno bonito de http://getbootstrap.com/2.3.2/base-css.html#icons
          'icon-map-marker'
        end

        # Might cause random bugs if enabled
        register_instance_option :pjax? do
          false
        end
        
        register_instance_option :controller do
          Proc.new do

            @address = @object

            if request.get?
              render :action => @action.template_name
            else
              permitted_params = params.permit(address:[@address.attributes.keys])

              @address.update_attributes(permitted_params[:address])

              flash[:success] = 'El mapa se ha guardado exitosamente'
              redirect_to rails_admin.address_map_path('Address', @address.id)
            end
          end
        end
      end
    end
  end
end

