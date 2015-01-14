class SchedulesController < ApplicationController

  # GET /services
  # GET /services.json
  def index
    @schedules = Schedule.where(status: params[:status], 
                                start_date: params[:start_date],
                                end_date: params[:end_date])

    if params[:aliada_id].present?
      @schedules = @schedules.where(aliada_id: params[:aliada_id])
    end

    if params[:zone_id].present?
      @schedules = @schedules.where(zone_id: params[:zone_id])
    end

    respond_to do |format|
      format.json { render json: @schedules }
     end
  end
end
