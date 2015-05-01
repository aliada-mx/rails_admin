# -*- encoding : utf-8 -*-
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
    @recurrences = @user.recurrences.active.sort_by { |r| r.wday }

    @one_timers = @user.services.one_timers.in_the_future.not_canceled.to_a
  end

  def previous_services
    @services = User.find(params[:user_id]).services.in_the_past.where('status NOT IN (?)',[:canceled_in_time, :canceled])
  end

  def canceled_services
    @services = User.find(params[:user_id]).services.canceled
  end

  def clear_session
    reset_session
  end

  def user_account
    redirect_to edit_users_path(current_user.id)
  end


  private
    def set_user
      @user = User.find(params[:user_id]) if params[:user_id]
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
