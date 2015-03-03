class AliadasAvailabilityController < ApplicationController
  def for_duration
    hours = params[:hours]


    requested_service = Service.new()
    
    #Example of to pass a date into the calendarario.html.erb partial
    @dates =  {Date.new(2015,1,3) => ['8:00', '9:00', '10:00', '11:00', '12:00'] }

    @dates =  {"03-#{rand(30).to_s % '%0D'}-2015" => {times: [{value: '8:00', text: '8:00 am'}, {value: '9:00', text: '9:00 am' }] } }
    
    return render json: { status: :success, dates_times: @dates }
  end
end
