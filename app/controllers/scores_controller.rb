class ScoresController < ApplicationController
  
  authorize_resource
  before_filter :set_user

  def score_service
    service = @user.services.find(params[:service_id])
    score = Score.create(user_id: service.user_id, value: params[:value], aliada_id: service.aliada_id, comment: params[:comment], service_id: params[:service_id])

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
