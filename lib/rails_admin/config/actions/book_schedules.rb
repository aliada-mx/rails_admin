# -*- encoding : utf-8 -*-
require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class BookSchedules < RailsAdmin::Config::Actions::Base

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          # Escoger uno bonito de http://getbootstrap.com/2.3.2/base-css.html#icons
          'icon-folder-open'
        end

        # Might cause random bugs if enabled
        register_instance_option :pjax? do
          false
        end
        
        register_instance_option :controller do
          Proc.new do
            @objects = list_entries(@model_config, :book_schedules)

            @objects.map do |schedule|
              schedule.status = 'booked'
              schedule.service_id = nil
              schedule.recurrence_id = nil
              schedule.user_id = nil
              schedule.save!
            end
            flash[:success] = 'Se han reservado las horas de servicio'
            redirect_to back_or_index
          end
        end
      end
    end
  end
end

