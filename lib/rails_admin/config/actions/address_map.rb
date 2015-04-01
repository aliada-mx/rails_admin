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

            if request.get?

              render :action => @action.template_name
            end
            services = if @object.blank?
                          @objects = list_entries(@model_config, :charge_services)
                        else
                          [ @object ]
                       end

            Resque.enqueue(ServiceCharger, services.map(&:id))

            flash[:success] = 'Se han puesto en cola los servicios a cobrar, los erróneos aparecerán como tickets'
            redirect_to back_or_index
          end
        end
      end
    end
  end
end

