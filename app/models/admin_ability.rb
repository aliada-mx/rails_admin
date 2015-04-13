# -*- encoding : utf-8 -*-
class AdminAbility
  include CanCan::Ability

  def initialize(user)
    if user
      if user.admin?
        can :access, :rails_admin
        can :dashboard
        can :manage, :all

        can :create_aliada_working_hours
        can :show_aliada_calendar
        can :charge_services
        can :modify_schedules_batch
      end
    end
  end
end
