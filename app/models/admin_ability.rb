class AdminAbility
  include CanCan::Ability

  def initialize(user)
    if user
      if user.admin?
        can :access, :rails_admin
        can :dashboard
        can :manage, :all

        can :tickets_resumen
      end
    end
  end
end

