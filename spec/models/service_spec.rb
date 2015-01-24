feature 'Service' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 00:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent') }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:service){ create(:service,
                         aliada: aliada,
                         user: user,
                         recurrence: recurrence,
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
      create(:schedule, datetime: current_datetime + i.hour)
    end
  end

  # Create the needed schedules
  before(:each, recurrent: true) do
    current_datetime = starting_datetime
    ending_datetime = starting_datetime + Setting.future_horizon_months.months

    while current_datetime < ending_datetime do
      Rails.logger.debug "puts Building schedules current_datetime #{current_datetime} and ending_datetime #{ending_datetime}"

      schedule = create(:schedule, datetime: current_datetime)

      current_datetime += 1.hour
    end
  end

  describe '#book_schedules!' do
    it 'allows it to mark one time service schedules´ as booked', recurrent:false do
      expect(Schedule.booked.count).to be 0
      expect(Schedule.available.count).to be 5

      service.book_schedules!

      expect(Schedule.booked.count).to be 5
      expect(Schedule.available.count).to be 0
    end

    it 'allows it to mark recurrent service schedules´ as booked', recurrent: true do
      service.service_type = recurrent_service
      Rails.logger.debug "before Service type is #{service.service_type.name}"
      service.save!

      service.book_schedules!
    end
  end
end
