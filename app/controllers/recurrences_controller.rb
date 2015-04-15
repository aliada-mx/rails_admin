# -*- encoding : utf-8 -*-
class RecurrencesController < ApplicationController
  layout 'two_columns'

  before_filter :set_user

  def set_user
    @user = User.find(params[:user_id])
  end

  def edit
    @any_aliada = OpenStruct.new({id: 0, name: 'Cualquier Aliada'})

    if current_user.admin?
      @aliadas = Aliada.all.order(:first_name) + [@any_aliada]
    else
      @aliadas = @user.aliadas + [@any_aliada]
    end

    @recurrence = Recurrence.find(params[:recurrence_id])
  end
end
