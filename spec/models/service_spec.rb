# -*- coding: utf-8 -*-
feature 'Service' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrence){ create(:recurrence, 
                            weekday: starting_datetime.weekday,
                            hour: starting_datetime.hour,
                            periodicity: 7) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent') }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:service){ create(:service,
                         aliada: aliada,
                         user: user,
                         recurrence: recurrence,
                         zone: zone,
                         service_type: one_time_service,
                         datetime: starting_datetime + 1.day,
                         estimated_hours: 3) }
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  before(:each, recurrent: false) do
    # Tomorrow because we never book for the same day, and - 1 hour to account the aliada traveling time
    create_one_timer!(starting_datetime + 1.day - 1.hour, hours: 4, conditions: {aliada: aliada, zone: zone} )
  end

  # Create the needed schedules
  before(:each, recurrent: true) do
    # Tomorrow because we never book for the same day, and - 1 hour to account the aliada traveling time
    create_recurrent!(starting_datetime + 1.day - 1.hour, hours: 4, periodicity: 7, conditions: {aliada: aliada, zone: zone})
  end

  describe '#book_aliada!' do
    it 'allows it to mark one time service schedules´ as booked', recurrent: false do
      available_schedules = Schedule.available_for_booking(zone, starting_datetime_to_book_services)
      expect(available_schedules.count).to be 4
      expect(Schedule.booked.count).to be 0

      service.book_aliada!

      expect(Schedule.booked.count).to be 4
      expect(Schedule.available_for_booking(zone, starting_datetime_to_book_services).count).to be 0
    end

    it 'allows it to mark recurrent service schedules´ as booked', recurrent: true do
      available_schedules = Schedule.available_for_booking(zone, starting_datetime_to_book_services)
      expect(available_schedules.count).to be 20
      expect(Schedule.booked.count).to be 0

      service.service_type = recurrent_service
      service.save!

      service.book_aliada!

      expect(Schedule.booked.count).to be 20 
      expect(available_schedules.count).to be 0
    end
  end

  describe '#datetime_within_working_hours' do
    it 'validates the service doesnt begin too early' do
      too_early = Time.zone.now.change(hour: Setting.beginning_of_aliadas_day - 1)

      service.datetime = too_early

      expect(service).to be_invalid
      expect(service.errors.messages).to have_key :datetime
      expect(service.errors.messages[:datetime].first).to include 'No podemos registrar un servicio que empieza o termina fuera del horario de trabajo'
    end

    it 'validates the service doesnt end too late' do
      too_late = '2014-10-31 18:00:00 -0600'.in_time_zone

      service.datetime = too_late

      expect(service).to be_invalid
      expect(service.errors.messages).to have_key :datetime
      expect(service.errors.messages[:datetime].first).to include 'No podemos registrar un servicio que empieza o termina fuera del horario de trabajo'
    end

    it 'validates a service ending at the end of aliadas day' do
      service.datetime = '2015-01-27 17:00:00'.in_time_zone

      expect(service).to be_valid
    end
  end

  describe '#datetime_is_hour_o_clock' do
    it 'validates the service ends in an hour o clock' do
      service.datetime = '2015-02-19 17:30:00'.in_time_zone

      expect(service).to be_invalid
      expect(service.errors.messages).to have_key :datetime
      expect(service.errors.messages[:datetime].first).to include 'Los servicios solo pueden crearse en horas en punto'
    end
  end

  describe '#days_count_to_end_of_recurrency' do
    it 'returns 4 for the number of thursdays on january 2015 without counting the first' do
      expect(starting_datetime).to eql Time.zone.parse('01 Jan 2015 07:00:00')
      expect(Setting.time_horizon_days).to be 30
      expect(service.days_count_to_end_of_recurrency).to be 4
    end
  end

  describe '#amount_to_bill' do
    it 'returns the amount result of calculating hours and multiplying by price' do
      s = Service.create(price: 65,
                         begin_time: Time.now, 
                         end_time: Time.now + 3.hour,
                         datetime: starting_datetime,
                         estimated_hours: 3,
                         service_type: one_time_service
                         )
      expect(s.amount_to_bill).to be 195.0
    end
    it 'returns 0 with invalid begin and end' do
      s = Service.create(price: 65,
                         service_type: one_time_service,
                         begin_time: Time.now, 
                         end_time: Time.now - 3.hour,
                         datetime: starting_datetime,
                         estimated_hours: 3
                         )
      expect(s.amount_to_bill).to be 0
    end
  end
end
