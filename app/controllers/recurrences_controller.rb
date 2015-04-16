# -*- encoding : utf-8 -*-
class RecurrencesController < ApplicationController
  layout 'two_columns'

  before_filter :set_user

  def edit
    @any_aliada = OpenStruct.new({id: 0, name: 'Cualquier Aliada'})

    if current_user.admin?
      @aliadas = Aliada.all.order(:first_name) + [@any_aliada]
    else
      @aliadas = @user.aliadas + [@any_aliada]
    end

    @recurrence = Recurrence.find(params[:recurrence_id])
  end

  def update
    recurrence = @user.recurrences.find(params[:recurrence_id])

    if params[:update_button]
      recurrence.update_existing!(recurrence_params)
    elsif params[:cancel_button]
      recurrence.cancel_all!
    end

    return render json: { status: :success, next_path: next_services_users_path(@user) }
  end

  private
    def recurrence_params
      params.require(:recurrence).permit(Recurrence::ATTRIBUTES_SHARED_WITH_SERVICE + [ {extra_ids: []} ])
    end

    def set_user
      @user = User.find(params[:user_id])
    end
end
