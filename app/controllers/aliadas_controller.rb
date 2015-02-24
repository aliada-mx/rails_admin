class AliadasController < ApplicationController

  def services 
    #this should be changed to aliada, but for debuggin it riffs
    # save_and_open_pages
    @aliada = Aliada.find_by(authentication_token: params[:token])
    
    
    if @aliada 
      @upcoming_services = Service.joins(:address).where(aliada_id: @aliada.id)
      @message = 'Token correct'
    else
      render text: 'Ruta invalida, ponte en contacto con Aliada' + params[:token]
    end
    
  end
  
end
