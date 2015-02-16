class AliadaWorkingHour < Recurrence

  default_scope { where(owner: 'aliada') }

  rails_admin do
    label_plural 'horarios de aliadas'
    parent Aliada
    navigation_icon 'icon-time'
  end
end

