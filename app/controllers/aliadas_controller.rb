# -*- encoding : utf-8 -*-
class AliadasController < ApplicationController
  
  def confirm
    @aliada = Aliada.find_by(authentication_token: params[:token])
    @service_to_confirm = Service.find_by(id: params[:service], aliada_id: @aliada.id)
    @service_to_confirm.confirmed = true;
    @service_to_confirm.save!
    
    redirect_to :back
  end
  
  def finish
    @aliada = Aliada.find_by(authentication_token: params[:token])
    @service_to_finish = Service.where(id: params[:service], 
                                       aliada_id: @aliada.id).first
    if @service_to_finish.present?

      if params[:hour] == 'cancelado'
        @service_to_finish.cancel 
      else
        hours = params[:hour].to_i
        min = params[:min].to_i
        hours = hours + (min/60.0)
        
        @service_to_finish.hours_worked = hours
        #@service_to_finish.aliada_reported_begin_time = ActiveSupport::TimeZone["Mexico City"].parse("#{params[:begin_hour]}:#{params[:begin_min]}")
        #@service_to_finish.aliada_reported_end_time = ActiveSupport::TimeZone["Mexico City"].parse("#{params[:end_hour]}:#{params[:end_min]}")
        @service_to_finish.finish
      end
      redirect_to :back
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' 
    end
  end

  def services 
   
    @aliada = Aliada.find_by(authentication_token: params[:token])
    
    if @aliada 
      #must implement today or tomorrow after 6pm, etc...
      now = ActiveSupport::TimeZone["Mexico City"].now
      date_to_show = if now.hour < 18
                       ActiveSupport::TimeZone["Mexico City"].today 
                     else
                       ActiveSupport::TimeZone["Mexico City"].today + 1.day
                     end
     
      #pulls unfinished services from the database, so we only present the worked services to the aliada
      @unfinished_services = Service.joins(:user).where(aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", now.utc)
      @upcoming_services = Service.joins(:address).order('datetime ASC').where(aliada_id: @aliada.id, :datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).not_canceled.joins(:user) 
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token]
    end
  end
end
 
