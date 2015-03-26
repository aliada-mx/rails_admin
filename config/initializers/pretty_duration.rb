class Integer
  def pretty_duration
      parse_string = 
          if self < 3600
              '%M:%S'
          else
              '%H:%M'
          end
      Time.at(self).utc.strftime(parse_string)
  end
end
