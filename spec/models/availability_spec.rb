describe 'Availability' do
  include TestingSupport::SchedulesHelper
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 15:00:00 UTC') } # 4 pm on Mexico City TZ
  let!(:user) { create(:user) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:aliada) { create(:aliada, created_at: starting_datetime) }
  let!(:aliada_2) { create(:aliada, created_at: starting_datetime) }
  let!(:zone_1) { create(:zone) }
  let!(:one_time_service_type) { create(:service_type, name: 'one-time') }
  let!(:recurrent_service_type) { create(:service_type, name: 'recurrent') }
  let!(:address_1){ create(:address)}
  let!(:one_time_service){ create(:service,
                                   user: user,
                                   zone: zone_1,
                                   service_type: one_time_service_type,
                                   datetime: starting_datetime,
                                   estimated_hours: 3,
                                   address: address_1) }
  let!(:recurrent_service){ create(:service,
                                   user: user,
                                   recurrence: recurrence,
                                   zone: zone_1,
                                   service_type: recurrent_service_type,
                                   datetime: starting_datetime,
                                   estimated_hours: 3,
                                   address: address_1) }

  before do
    @first_interval = create_one_timer!(starting_datetime, hours: 5, conditions: {aliada_id: aliada.id, zones: [zone_1]} )

    @last_interval = create_one_timer!(starting_datetime + 5.hours , hours: 5, conditions: {aliada_id: aliada.id, zones: [zone_1]} )
    @last_schedule = @last_interval.schedules.last

    @aliadas_availability = Availability.new

    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  describe '#schedules_intervals' do
    it 'returns a list of schedules intervals' do
      @aliadas_availability.schedules_intervals.each do |interval|
        expect(interval.class).to be ScheduleInterval
      end
    end
  end

  describe '#schedules' do
    it 'returns a list of schedules' do
      @aliadas_availability.schedules.each do |schedule|
        expect(schedule.class).to be Schedule
      end
    end
  end

  describe '#delete_if' do
    it 'removes aliadas with empty intervals' do
      @aliadas_availability.add('thursday-1', @first_interval, aliada.id)
      @aliadas_availability.add('thursday-8', @last_interval, aliada_2.id)

      @aliadas_availability.delete_if do |aliada_id, wday_hour_intervals|

        wday_hour_intervals.delete_if do |wday_hour, intervals_hash|

          intervals_hash.delete_if do |interval_key, interval|
            interval.include_schedule? @last_schedule
          end

        intervals_hash.empty?
        end

      wday_hour_intervals.empty?
      end

      expect(@aliadas_availability.has_key?(aliada.id)).to be true
      expect(@aliadas_availability.has_key?(aliada_2.id)).to be false
    end
  end

  describe '#for_calendar' do
    it 'should return the availability in the right format' do
      @aliadas_availability.add('key', @first_interval, aliada.id)

      dates_times = @aliadas_availability.for_calendario('Mexico City', zone_1)

      expect(dates_times).to eql ( { "2015-01-01"=>[{:value=>"09:00", :friendly_time=>" 9:00 am", :friendly_datetime=>"01 de enero 2015,  9:00 am"}] } )
    end
  end

  describe '#for_aliada' do
    it 'returns an aliada availability with a key' do
      @aliadas_availability.add('key', @first_interval, aliada.id)

      availability = @aliadas_availability.for_aliada(aliada)

      expect(availability.aliada).to eql aliada
    end

    it 'adds schedules with the same aliada id as the availabilitys' do
      @aliadas_availability.add('key', @first_interval, aliada.id)

      aliada_availability = @aliadas_availability.for_aliada(aliada)

      expect(aliada_availability.schedules_intervals.first.aliada_id).to eql aliada.id
    end
  end

  describe '#add' do
    it 'adds schedules' do
      @aliadas_availability.add('key', @first_interval, aliada.id)

      expect(@aliadas_availability.schedules.map(&:id).sort).to eql @first_interval.schedules.map(&:id).sort
    end

    it 'adds schedules one time unique by interval key in order' do
      @aliadas_availability.add('key', @first_interval, aliada.id)
      @aliadas_availability.add('key', @last_interval, aliada.id)

      expect(@aliadas_availability.size).to eql 1
      expect(@aliadas_availability[aliada.id].size).to eql 1
      expect(@aliadas_availability[aliada.id]['key'].size).to eql 2
    end

    it 'converts schedules to schedules intervals' do
      @aliadas_availability.add('key', @first_interval, aliada.id)

      expect(@aliadas_availability.schedules_intervals.first.class).to eql ScheduleInterval
    end
  end
end
