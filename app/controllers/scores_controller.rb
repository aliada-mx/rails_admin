# -*- encoding : utf-8 -*-
class ScoresController < ApplicationController
  
  authorize_resource
  before_filter :set_user

  def score_service
    service = @user.services.find(params[:service_id])

    score = Score.find_or_create_by(user: @user,
                                    aliada: service.aliada,
                                    service: service)
    score.value = params[:value]
    score.comment = params[:comment]
    score.save!

    if request.get?

      flash[:success] = 'Gracias por calificar a tu aliada!'

      redirect_to previous_services_users_path(@user)
    elsif request.post?

      render json: { status: :success, score: score }
    end
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end
end
