module ApplicationHelper
  def humanize_hours hours
    minutes = hours.hours / 60

    hours, minutes = minutes.divmod(60)

    humanized = "#{hours.to_i} hrs."
    unless minutes.zero?
      humanized += " #{minutes.to_i} mins."
    end
    humanized
  end

  def controller_action_name
    "#{params[:controller]}-#{params[:action]}".parameterize
  end

  def ensure_plural(word)
    word[-1] == 's' ? word : word + 's'
  end

  def ceil_and_strip_insignificat_zeros(number)
    number.ceil.to_s.sub(/(\.)(\d*[1-9])?0+\z/, '\1\2').sub(/\.\z/, '')
  end
end
