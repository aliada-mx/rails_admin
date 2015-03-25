class AliadasController < ApplicationController
  
  def finish
    
    @aliada = Aliada.find_by(authentication_token: params[:token])
    @service_to_finish = Service.where(id: params[:service],  aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", DateTime.now).take
    if @service_to_finish
      @service_to_finish.aliada_reported_begin_time =  ActiveSupport::TimeZone["Mexico City"].parse(params[:begin_time])
      @service_to_finish.aliada_reported_end_time = ActiveSupport::TimeZone["Mexico City"].parse(params[:end_time])
      @service_to_finish.finish!
      @service_to_finish.user.charge_service!(@service_to_finish.id)

      redirect_to :back
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' 
    end
  end

  def services 
   
    @aliada = Aliada.find_by(authentication_token: params[:token])
    
    if @aliada 
     #must implement today or tomorrow after 6pm, etc...
     # @tz = ActiveSupport::TimeZone["Mexico City"]
      now = ActiveSupport::TimeZone["Mexico City"].now #Time.zone.now
     # cutoff_time = now.clone #so we get a new object and not a refernce
     # cutoff_time.change(hour: 10)
      
      date_to_show = if now.hour <= 19
                       ActiveSupport::TimeZone["Mexico City"].today
                     else
                       ActiveSupport::TimeZone["Mexico City"].today + 1.day
                     end
     
      @unfinished_services = Service.joins(:user).where(aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", now.utc)
      @upcoming_services = Service.joins(:address).where(aliada_id: @aliada.id, :datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).not_canceled.joins(:user) 
      @message = "#{@aliada.id}"
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token]
    end
  end
end
 
