# -*- encoding : utf-8 -*-
module ServiceTypeHelper
  def should_hide(service)
    in_initial_service = params[:controller] == 'services' && params[:action] == 'initial'

    return false if in_initial_service

    service.service_type.present? && ( service.try(:recurrent?) || service.try(:one_timer_from_recurrent?) )
  end 
end
