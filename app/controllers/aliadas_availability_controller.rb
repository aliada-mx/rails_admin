class AliadasAvailabiityController < ApplicationController
  def for_duration
    hours = params[:hours]


    requested_service = Service.new()
    
    #Example of to pass a date into the calendarario.html.erb partial
    @dates =  {Date.new(2015,1,2) => ['8:00', '9:00', '10:00', '11:00', '12:00'] }

    map = {}
    @dates.each_pair do |k,v|
      map[k.strftime('%m-%d-%Y')] = v
    end
    @dates = map
    
    @dates_parsed = ActiveSupport::JSON.encode(@dates).html_safe

    return render json: { status: :success, dates: @dates_parsed }
  end
end
