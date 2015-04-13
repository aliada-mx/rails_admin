# -*- encoding : utf-8 -*-
require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class ModifySchedulesBatch < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :link_icon do
          # Escoger uno bonito de http://getbootstrap.com/2.3.2/base-css.html#icons
          'icon-list'
        end

        # Might cause random bugs if enabled
        register_instance_option :pjax? do
          false
        end
        
        register_instance_option :controller do
          Proc.new do
            
            if request.get?
            @aliadas = Aliada.all
            @hours = ActiveSupport::TimeZone['Mexico City'].parse('8 AM')
            else
              
            #redirect_to back_or_index
            render :action => @action.template_name
            end
          end
        end

      end
    end
  end
end

