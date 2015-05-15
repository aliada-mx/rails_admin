# -*- encoding : utf-8 -*-
class AliadasController < ApplicationController
  include AliadaSupport::DatetimeSupport

  before_filter :set_aliada
  
  def confirm
    @service_to_confirm = Service.find_by(id: params[:service_id], aliada_id: @aliada.id)
    @service_to_confirm.confirmed = true
    @service_to_confirm.save!
    
    redirect_to :back
  end

  def unassign
    @aliada.services.find(params[:service_id])
    @service_to_unassign = Service.find(params[:service_id])

    if request.post?

      @service_to_unassign.unassign!

      return redirect_to aliadas_services_path(@aliada.authentication_token)
    end
  end
  
  def finish
    @service_to_finish = @aliada.services.find(params[:service][:id])
                                       
    hours = params[:service][:hour].to_i
    min = params[:service][:min].to_i
    hours = hours + (min/60.0)
    
    @service_to_finish.hours_worked = hours
    @service_to_finish.finish
    @service_to_finish.save!

    redirect_to :back
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

    @services_to_finish = @aliada.services.where(status: 'aliada_assigned')
                                          .order('datetime ASC')
                                          .where("datetime <= ?", Time.zone.now)

    @worked_services = @aliada.services.where(status: 'finished')
                                       .order('datetime ASC')
                                       .where('hours_worked IS NOT NULL')
                                       .where('hours_worked != 0')
                                       .where(:datetime => this_week_range)
  end

  private
    def set_aliada
      @aliada = Aliada.find_by(authentication_token: params[:token])

      render text: 'Ruta invalida, ponte  en contacto con aliada' + params[:token] unless @aliada
    end
end
 
