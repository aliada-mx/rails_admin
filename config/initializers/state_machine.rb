# State machine fix for rails 4
# for more info see:
# http://dev.mensfeld.pl/2014/07/state-machine-gem-and-rails-activemodel-4-1-nomethoderror-protected-method-around_validation-called-for-statemachine/
module StateMachine
  # Extensions for integrations of state machine
  module Integrations
    # ActiveModel extension that fixes the non-public around_validation error
    module ActiveModel
      send :public, :around_validation
    end
  end
end
