require 'rails_admin/config/fields/types/datetime'

module RailsAdmin
  module Config
    module Fields
      module Types
        class DayMonth < RailsAdmin::Config::Fields::Types::Datetime
          @format = :day_month
          @i18n_scope = [:date, :formats]
          @js_plugin_options = {
            'showTime' => false,
          }

          def parse_input(params)
            params[name] = self.class.normalize(params[name], localized_date_format).to_date if params[name].present?
          end
        end
      end
    end
  end
end

RailsAdmin::Config::Fields::Types::register(:day_month, RailsAdmin::Config::Fields::Types::DayMonth)
