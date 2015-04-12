# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
feature 'Service' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  let(:timezone){ 'UTC' }
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:conekta_card){ create(:conekta_card) }
  let!(:recurrence){ create(:recurrence, 
                            weekday: ( starting_datetime + 1.day - 1.hour).weekday,
                            hour: ( starting_datetime + 1.day - 1.hour).hour,
                            periodicity: 7) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent', price_per_hour: 65) }
  let!(:one_time_service) { create(:service_type, name: 'one-time', price_per_hour: 105) }
  let!(:one_time_from_recurrent) { create(:one_time_from_recurrent) }
  let!(:service){ create(:service,
                         aliada: aliada,
                         user: user,
                         recurrence: recurrence,
                         zone: zone,
                         timezone: 'UTC',
                         service_type: one_time_service,
                         datetime: starting_datetime + 1.day,
                         estimated_hours: 3) }
  before do
    Timecop.freeze(starting_datetime)
    allow_any_instance_of(Service).to receive(:timezone).and_return(timezone)
  end

  after do
    Timecop.return
  end

  before(:each, recurrent: false) do
    # Tomorrow because we never book for the same day
    create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada, zones: [zone]})
  end

  # Create the needed schedules
  before(:each, recurrent: true) do
    # Tomorrow because we never book for the same day
    create_recurrent!(starting_datetime + 1.day, hours: 4, periodicity: 7, conditions: {aliada: aliada, zones: [zone]})
  end

  describe '#book_an_aliada' do
    it 'allows it to mark one time service schedules´ as booked', recurrent: false do
      available_schedules = Schedule.for_booking(zone, starting_datetime_to_book_services)
      expect(available_schedules.count).to be 4
      expect(Schedule.booked.count).to be 0

      service.book_an_aliada

      expect(Schedule.padding.count).to be 1
      expect(Schedule.booked.count).to be 3
      expect(Schedule.for_booking(zone, starting_datetime_to_book_services).available.count).to be 0
    end

    it 'allows it to mark recurrent service schedules´ as booked', recurrent: true do
      available_schedules = Schedule.for_booking(zone, starting_datetime_to_book_services).available
      expect(available_schedules.count).to be 20
      expect(Schedule.booked.count).to be 0

      service.service_type = recurrent_service
      service.save!

      service.book_an_aliada

      expect(Schedule.booked.count).to be 15
      expect(Schedule.padding.count).to be 5
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
      too_late = '2014-10-31 04:00:00 -0600'.in_time_zone

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

  describe '#requested_schedules' do
    before do
      @schedule_interval = service.requested_schedules
    end

    it 'should have valid schedule intervals starting datetimes' do
      expect(@schedule_interval.beginning_of_interval).to eql starting_datetime + 1.day
    end

    it 'should have valid schedule intervals ending datetimes' do
      expect(@schedule_interval.ending_of_interval).to eql starting_datetime + 1.day + 4.hours
    end

    it 'should have a correct number of schedule intervals' do
      expect(@schedule_interval.size).to eql 5
    end
  end

  describe '#amount_by_reported_hours' do
    it 'returns the amount result of calculating hours and multiplying by price' do
      s = Service.create(price: 65,
                         aliada_reported_begin_time: Time.now, 
                         aliada_reported_end_time: Time.now + 3.hour,
                         datetime: starting_datetime,
                         estimated_hours: 3,
                         service_type: recurrent_service
                         )
      expect(s.amount_by_reported_hours).to be 195.0
    end
    it 'returns 0 with invalid begin and end' do
      s = Service.create(price: 65,
                         service_type: one_time_service,
                         aliada_reported_begin_time: Time.now, 
                         aliada_reported_end_time: Time.now - 3.hour,
                         datetime: starting_datetime,
                         estimated_hours: 3
                         )
      expect(s.amount_by_reported_hours).to be 0
    end
  end

  describe '#charge_service!' do

    it 'Creates a ticket on Conekta::Error' do
      user.create_payment_provider_choice(conekta_card)
      service.price= 65
      service.status = 'finished'
      service.user_id = user.id
      service.aliada_reported_begin_time = Time.now
     
      service.aliada_reported_end_time = Time.now + 3.hours
      service.datetime = starting_datetime
      service.estimated_hours = 3
      
      service.save
      conekta_card.token = nil
      conekta_card.save
      service.charge!
      expect(Ticket.all.count).to eql 1
     
    end

    it 'Charges the user using the default payment provider' do
      user.create_payment_provider_choice(conekta_card)
      service.price= 65
      service.status = 'finished'
      service.user_id = user.id
      service.aliada_reported_begin_time = Time.zone.now
      
      service.aliada_reported_end_time = Time.zone.now + 3.hours
      service.datetime = starting_datetime
      service.estimated_hours = 3
      
      service.save
      
      VCR.use_cassette('conekta_user_charge', match_requests_on:[:conekta_charge]) do
        service.charge!
      end
      expect(Payment.all.count).to eql 1
    end
  end

  describe '#amount_to_bill' do
    it 'calculates using the billable hours when these are set' do
      service.billable_hours = 3
      service.aliada_reported_begin_time = starting_datetime
      service.aliada_reported_end_time = starting_datetime + 4.hours
    
      expect(service.amount_to_bill).to eql 315
    end

    it 'calculates using the reported hours when these are set and the billable_hours are not' do
      service.aliada_reported_begin_time = starting_datetime
      service.aliada_reported_end_time = starting_datetime + 4.hours
    
      expect(service.amount_to_bill).to eql 420
    end
  end

  describe '#friendly_total_hours' do
    it 'uses the billable hours if available' do
      service.billable_hours = 3.50
      service.aliada_reported_begin_time = starting_datetime
      service.aliada_reported_end_time = starting_datetime + 4.hours
      

      expect(service.friendly_total_hours).to eql '3 horas 30 minutos'
    end

    it 'uses the reported hours if the billable_hours are empty' do
      service.aliada_reported_begin_time = starting_datetime
      service.aliada_reported_end_time = starting_datetime + 4.hours + 30.minutes
      

      expect(service.friendly_total_hours).to eql '4 horas 30 minutos'
    end
  end

  describe '#ensure_updated_recurrence!' do
    it 'saves the recurrence hour and weekday with the service timezone' do
      allow_any_instance_of(Service).to receive(:timezone).and_return('Mexico City')

      service.service_type = recurrent_service
      service.ensure_updated_recurrence!

      expect(service.recurrence.hour).to be 7
      expect(service.recurrence.weekday).to eql 'friday'
    end
  end
end
