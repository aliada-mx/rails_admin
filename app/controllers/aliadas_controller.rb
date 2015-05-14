# -*- encoding : utf-8 -*-
class AliadasController < ApplicationController

  before_filter :set_aliada
  
  def confirm
    @service_to_confirm = Service.find_by(id: params[:service], aliada_id: @aliada.id)
    @service_to_confirm.confirmed = true
    @service_to_confirm.save!
    
    redirect_to :back
  end

  def unassign
    @service_to_unassign = @aliada.services.find(params[:service])

    @service_to_unassign.unassign!

    redirect_to :back
  end
  
  def finish
    @service_to_finish = @aliada.services.find(params[:service])
                                       
    if @service_to_finish.present?

      hours = params[:hour].to_i
      min = params[:min].to_i
      hours = hours + (min/60.0)
      
      @service_to_finish.hours_worked = hours
      @service_to_finish.finish

      redirect_to :back
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' 
    end
  end

  def services 
    @aliada.track_webapp_view(request)

    #must implement today or tomorrow after 6pm, etc...
    now = ActiveSupport::TimeZone["Mexico City"].now
    date_to_show = if now.hour < 18
                     ActiveSupport::TimeZone["Mexico City"].today 
                   else
                     ActiveSupport::TimeZone["Mexico City"].today + 1.day
                   end
   
    #pulls unfinished services from the database, so we only present the worked services to the aliada
    @unfinished_services = @aliada.services.where(status: 'aliada_assigned').where("datetime <= ?", now.utc)
    @upcoming_services = @aliada.services.joins(:address).order('datetime ASC').where(:datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).not_canceled.not_aliada_missing
  end

  def services 
    @aliada.track_webapp_view(request)

    #must implement today or tomorrow after 6pm, etc...
    now = ActiveSupport::TimeZone["Mexico City"].now
    date_to_show = if now.hour < 18
                     ActiveSupport::TimeZone["Mexico City"].today 
                   else
                     ActiveSupport::TimeZone["Mexico City"].today + 1.day
                   end
   
    #pulls unfinished services from the database, so we only present the worked services to the aliada
    @unfinished_services = @aliada.services.where(status: 'aliada_assigned').where("datetime <= ?", now.utc)
    @upcoming_services = @aliada.services.joins(:address).order('datetime ASC').where(:datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).not_canceled.not_aliada_missing
  end

  private
    def set_aliada
      @aliada = Aliada.find_by(authentication_token: params[:token])

      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token] unless @aliada
    end
end
 
