shared_context 'schedules and schedules intervals' do
  let!(:aliada){ create(:aliada) }
  let!(:other_aliada){ create(:aliada) }
  starting_datetime = Time.now.utc.change({hour: 13})
  ending_datetime = starting_datetime + 6.hour

  before do
    6.times do |i|
      # switch chosen aliada
      chosen_aliada = i > 2 ? aliada : other_aliada

      create(:schedule, datetime: starting_datetime + i.hour, status: 'available', aliada: chosen_aliada)
    end

    @six_hours_schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
    @eight_hours_schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime + 1.hours)
    @two_hours_schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime - 4.hours)
    @six_available_schedules = Schedule.available.ordered_by_user_datetime
  end
end
