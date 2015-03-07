class Ability
  include CanCan::Ability

  def initialize(current_user, params)
    current_user ||= User.new

    # Logged-in Users can
    if current_user.persisted?
      can do |action, subject_class, subject|
        if subject_class == User
          if [:read, :update, :next_services, :previous_services, :edit].include? action
            if current_user.admin?
              true
            # User objects abilities
            elsif subject.present? # subject is the user being edited, read, updated...
              subject.id == current_user.id
            # User controller abilities
            elsif params.include? :user_id
              current_user.id == params[:user_id].to_i
            else
              false
            end
          end
        elsif subject_class == Score
          if action == :create_by_service_id
            if current_user.admin?
              true
            elsif params.include? :service_id
              Service.find(params[:service_id]).user_id == current_user.id
            else
              false
            end
          end
        end
      end
    end
  end
end
