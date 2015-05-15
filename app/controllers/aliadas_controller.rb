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

  def next_services 
    @aliada.track_webapp_view(request, params)

    #must implement today or tomorrow after 6pm, etc...
    now = ActiveSupport::TimeZone["Etc/GMT+6"].now

    date_to_show = if now.hour < 18
                      ActiveSupport::TimeZone["Etc/GMT+6"].today 
                    else
                      ActiveSupport::TimeZone["Etc/GMT+6"].today + 1.day
                    end

    @upcoming_services = @aliada.services.joins(:address)
                                         .order('datetime ASC')
                                         .where(:datetime => date_to_show.beginning_of_day..date_to_show.end_of_day)
                                         .not_canceled.not_aliada_missing
  end

  def worked_services 
    @aliada.track_webapp_view(request, params)

    @unfinished_services = @aliada.services.where(status: 'aliada_assigned').where("datetime <= ?", Time.zone.now)
  end

  private
    def set_aliada
      @aliada = Aliada.find_by(authentication_token: params[:token])

      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token] unless @aliada
    end
end
 
