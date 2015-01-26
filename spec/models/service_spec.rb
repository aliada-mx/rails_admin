feature 'Service' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent') }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:service){ create(:service,
                         aliada: aliada,
                         user: user,
                         recurrence: recurrence,
                         zone: zone,
                         service_type: one_time_service,
                         datetime: starting_datetime,
                         billable_hours: 3) }
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  before(:each, recurrent: false) do
    ending_datetime = Time.zone.now + Setting.future_horizon_months.months
    current_datetime = starting_datetime

    5.times.each do |i|
      create(:schedule, datetime: current_datetime + i.hour, zone: zone, aliada: aliada)
    end
  end

  # Create the needed schedules
  before(:each, recurrent: true) do
    current_datetime = starting_datetime
    ending_datetime = starting_datetime + Setting.future_horizon_months.months

    while current_datetime < ending_datetime do
      Rails.logger.debug "puts Building schedules current_datetime #{current_datetime} and ending_datetime #{ending_datetime}"

      create(:schedule, datetime: current_datetime, zone: zone, aliada: aliada)

      current_datetime += 1.hour
    end
  end

  describe '#book_with!' do
    it 'allows it to mark one time service schedules´ as booked', recurrent:false do
      available_schedules = Schedule.available_for_booking(zone)
      expect(available_schedules.count).to be 5
      expect(Schedule.booked.count).to be 0

      service.book_aliada!

      expect(Schedule.booked.count).to be 5
      expect(Schedule.available_for_booking(zone).count).to be 0
    end

    it 'allows it to mark recurrent service schedules´ as booked', recurrent: true do
      available_schedules = Schedule.available_for_booking(zone)
      expect(available_schedules.count).to be 744 
      expect(Schedule.booked.count).to be 0

      service.service_type = recurrent_service
      service.save!

      service.book_aliada!

      expect(Schedule.booked.count).to be 25 
      expect(available_schedules.count).to be 719
    end
  end

  describe '#datetime_within_working_hours' do
    it 'validates the service doesnt begin  too early' do
      too_early = Time.zone.now.change(hour: Setting.beginning_of_aliadas_day - 1)

      service.datetime = too_early

      expect(service).to be_invalid
    end

    it 'validates the service doesnt end too late' do
      too_late = Time.zone.now.change(hour: Setting.end_of_aliadas_day + 1)

      service.datetime = too_late

      expect(service).to be_invalid
    end
  end
end
