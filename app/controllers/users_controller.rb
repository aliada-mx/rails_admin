class UsersController < ApplicationController
  layout 'one_column'
  load_and_authorize_resource
  before_filter :set_user

  def edit
    conekta_card = @user.default_payment_provider

    @saved_card = conekta_card.placeholder_for_form
  end

  def update
    if @user.update(user_params)
      # Devise has a bug where it logsout a user when it changes its own password
      # so we relog him back
      sign_in(@user, bypass: true) if params[:user][:password].present?

      flash[:success] = 'Guardamos exitosamente tus cambios'
    else
      flash[:alert] = @user.error_messages
    end

    redirect_to :back
  end

  def next_services
    one_time_service_type = ServiceType.one_time

    recurrent_services = @user.services.not_canceled.with_recurrence.to_a
    one_time = @user.services.not_canceled.in_the_future.to_a

    @services = ( recurrent_services + one_time ).select do |service|
      service.one_timer? && service.recurrence_id.nil? || service.recurrent?
    end.uniq
  end

  def previous_services
    @services = User.find(params[:user_id]).services.in_the_past.not_canceled
  end

  def clear_session
    reset_session
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end

    def user_params
      params.require(:user).permit(:first_name,
                                   :last_name,
                                   :email,
                                   :phone,
                                   :password,
                                   :password_confirmation)
    end
end
