# -*- encoding : utf-8 -*-
require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class CreateAliadaWorkingHours < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :link_icon do
          # Escoger uno bonito de http://getbootstrap.com/2.3.2/base-css.html#icons
          'icon-time'
        end

        # Might cause random bugs if enabled
        register_instance_option :pjax? do
          false
        end
        
        register_instance_option :controller do
          Proc.new do

            if request.post? and params[:recurrences]

              activated_recurrences = params[:recurrences][:activated_recurrences] ? params[:recurrences][:activated_recurrences] : []
              disabled_recurrences =  params[:recurrences][:disabled_recurrences] ? params[:recurrences][:disabled_recurrences] : []
              new_recurrences = params[:recurrences][:new_recurrences] ? params[:recurrences][:new_recurrences] : []

              AliadaWorkingHour.update_from_admin params[:id], activated_recurrences, disabled_recurrences, new_recurrences
              render json: { status: :success, url: rails_admin.create_aliada_working_hours_path }
            else
              # redirect_to back_or_index
              render :action => @action.template_name
            end            
          end
        end

      end
    end
  end
end

