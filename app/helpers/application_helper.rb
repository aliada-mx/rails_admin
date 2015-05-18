# -*- encoding : utf-8 -*-
module ApplicationHelper
  include AliadaSupport::DatetimeSupport

  def controller_action_name
    "#{params[:controller]}-#{params[:action]}".parameterize
  end

  def ensure_plural(word)
    word[-1] == 's' ? word : word + 's'
  end

  def ceil_and_strip_insignificat_zeros(number)
    number.ceil.to_s.sub(/(\.)(\d*[1-9])?0+\z/, '\1\2').sub(/\.\z/, '')
  end

  def in_admin_controller?
    params[:controller] == 'rails_admin/main'
  end

  def in_time_zone_formatted(datetime)
    I18n.l(datetime.in_time_zone('Etc/GMT+6'), format: :future)
  end

  def ensure_leading_zero(number)
    sprintf "%.1f", number
  end

  def controller?(*controller)
    controller.include?(params[:controller])
  end

  def action?(*action)
    action.include?(params[:action])
  end

  def format_date(date)
    I18n.l date, format: '%A %e de %B  a las %I %P'
  end
end
