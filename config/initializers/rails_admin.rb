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
    index                         # mandatory
    dashboard
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end

