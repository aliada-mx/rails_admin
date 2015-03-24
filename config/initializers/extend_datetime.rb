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
    
    # Iterate in a range step by step hours
    def iterate_in_hour_steps(start, end_)
      Enumerator.new { |y| loop { y.yield start; start += 1.hour } }.take_while { |d| d < end_ }
    end
    #
    # Iterate in a range step by step days
    def iterate_in_days_steps(start, end_)
      Enumerator.new { |y| loop { y.yield start; start += 1.day } }.take_while { |d| d < end_ }
    end
  end

  def dia_semana
    self.class.weekdays.select{ |day| day[1] == wday }.first.third
  end

  def weekday
    self.class.weekdays.select{ |day| day[1] == wday }.first.first
  end

  def beginning_of_aliadas_day
    self.change(hour: Setting.beginning_of_aliadas_day)
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
