class AliadasController < ApplicationController
  
  def finish
    
    @aliada = Aliada.find_by(authentication_token: params[:token])
    @service_to_finish = Service.where(id: params[:service],  aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", DateTime.now).take
    if @service_to_finish
      @service_to_finish.aliada_reported_begin_time =  ActiveSupport::TimeZone["Mexico City"].parse(params[:begin_time])
      @service_to_finish.aliada_reported_end_time = ActiveSupport::TimeZone["Mexico City"].parse(params[:end_time])
      @service_to_finish.finish!
      @service_to_finish.charge!

      redirect_to :back
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' 
    end
  end

  def services 
   
    @aliada = Aliada.find_by(authentication_token: params[:token])
    
    if @aliada 
      #must implement today or tomorrow after 6pm, etc...
      now = Time.zone.now
      date_to_show = if now.hour < Setting.show_tomorrow_services_cutoff
                       Time.zone.today
                     else
                       Time.zone.today + 1.day
                     end
     
      @unfinished_services = Service.joins(:user).where(aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", now)
      @upcoming_services = Service.joins(:address).where(aliada_id: @aliada.id, :datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).not_canceled.joins(:user) 
      
      @message = 'Token correct'
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token]
    end
  end
end
 
