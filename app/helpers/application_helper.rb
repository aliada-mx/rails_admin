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
end
