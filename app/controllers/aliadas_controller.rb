class AliadasController < ApplicationController
  
  def finish
     @aliada = Aliada.find_by(authentication_token: params[:token])
    @service_to_finish = Service.where(aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", DateTime.now).take
    if @service_to_finish
      
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token]
    end
  end

  def services 
   
    @aliada = Aliada.find_by(authentication_token: params[:token])
    
    
    if @aliada 
      #must implement today or tomorrow after 6pm, etc...
      date_to_show = if DateTime.now.hour < 19
                       Date.today
                     else
                       Date.tomorrow
                     end
      @unfinished_services = Service.joins(:user).where(aliada_id: @aliada.id, status: 'aliada_assigned').where("datetime <= ?", DateTime.now)
      @upcoming_services = Service.joins(:address).where(aliada_id: @aliada.id, :datetime => date_to_show.beginning_of_day..date_to_show.end_of_day).joins(:user)      
      @message = 'Token correct'
    else
      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token]
    end
  end
end
 
