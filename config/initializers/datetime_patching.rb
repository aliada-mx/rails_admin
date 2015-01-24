module WeekdayPatch
  # Modify the class including you
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def weekdays
      [
        ['sunday', 0, 'Domingo'],
        ['monday', 1, 'Lunes'],
        ['tuesday', 2, 'Martes'],
        ['wednesday', 3, 'Miércoles'],
        ['thursday', 4, 'Juéves'],
        ['friday', 5, 'Viernes'],
        ['saturday', 6, 'Sábado'],
      ]
    end
  end

  def weekday
    self.class.weekdays.select{ |day| day[1] == wday }.first.first
  end
end

class Time
  include WeekdayPatch
end

class DateTime
  include WeekdayPatch
end

class ActiveSupport::TimeWithZone
  include WeekdayPatch
end
