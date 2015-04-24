# -*- encoding : utf-8 -*-
require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class ChargeServices < RailsAdmin::Config::Actions::Base

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          # Escoger uno bonito de http://getbootstrap.com/2.3.2/base-css.html#icons
          'icon-shopping-cart'
        end

        # Might cause random bugs if enabled
        register_instance_option :pjax? do
          false
        end

        register_instance_option :http_methods do
          [:post,:get]
        end
        
        register_instance_option :controller do
          Proc.new do
            services = if @object.blank?
                          @objects = list_entries(@model_config, :charge_services)
                        else
                          [@object]
                       end
            # Force evaluation to avoid multiple queries
            services.to_a

            @services_without_amount_to_bill = services.select { |s| s.amount_to_bill.zero? }
            @services_already_paid = services.select { |s| s.paid? }

            @services_to_charge = services.select { |service| not service.paid? and not service.amount_to_bill.zero? }

            Resque.enqueue(ServiceCharger, @services_to_charge.map(&:id))

            render :action => @action.template_name
          end
        end
      end
    end
  end
end

