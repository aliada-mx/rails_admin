class AliadasController < ApplicationController

  def services 
    #this should be changed to aliada, but for debuggin it riffs
    # save_and_open_pages
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
      render text: 'Ruta invalida, ponte  en contacto con Aliada' + params[:token]
    end
  end
end
 
