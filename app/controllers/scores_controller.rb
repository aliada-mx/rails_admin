class ScoresController < ApplicationController
  
  authorize_resource

  def create_by_service_id
    service = Service.find(params[:service_id])
    score = Score.create(user_id: service.user_id, value: params[:value], aliada_id: service.aliada_id, comment: params[:comment], service_id: params[:service_id])
    
    return render json: { status: :success, score: score }

  end

end
