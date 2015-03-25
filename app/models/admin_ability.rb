class AdminAbility
  include CanCan::Ability

  def initialize(user)
    if user
      if user.admin?
        can :access, :rails_admin
        can :dashboard
        can :manage, :all

        can :create_aliada_working_hours
        can :charge_services
      end
    end
  end
end

