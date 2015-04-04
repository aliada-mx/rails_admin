# Register actions
RailsAdmin::Config::Actions.register(:create_aliada_working_hours, RailsAdmin::Config::Actions::CreateAliadaWorkingHours)

RailsAdmin::Config::Fields::Types::register(:show_aliada_calendar, RailsAdmin::Config::Actions::ShowAliadaCalendar)

RailsAdmin::Config::Actions.register(:charge_services, RailsAdmin::Config::Actions::ChargeServices)
 
RailsAdmin::Config::Actions.register(:address_map, RailsAdmin::Config::Actions::AddressMap)

RailsAdmin.config do |config|
  # By default rails admin does not support Inet fields so we force it
  class RailsAdmin::Config::Fields::Types::Inet < RailsAdmin::Config::Fields::Base
    RailsAdmin::Config::Fields::Types::register(self)
  end

  config.authorize_with :cancan, AdminAbility
  config.current_user_method(&:current_user)

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    
    create_aliada_working_hours do
      visible do
        bindings[:abstract_model].model.to_s == 'Aliada'
      end
    end
    
    show_aliada_calendar do
      visible do
        bindings[:abstract_model].model.to_s == 'Aliada'
      end
    end

    charge_services do
      visible do
        bindings[:abstract_model].model.to_s == 'Service'
      end
    end

    address_map do
      visible do
        bindings[:abstract_model].model.to_s == 'Address'
      end
    end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end


