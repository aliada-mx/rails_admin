describe 'Availability' do
  include TestingSupport::SchedulesHelper
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 16:00:00') }
  let!(:user) { create(:user) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:aliada) { create(:aliada, created_at: starting_datetime) }
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
    create_one_timer!(starting_datetime, hours: 5, conditions: {aliada_id: aliada.id, zone_id: zone_1.id})
    @first_five_schedules = Schedule.all.limit(5)
    @last_five_schedules = Schedule.all.where('id not in (?)', @first_five_schedules.map(&:id))

    @aliadas_availability = Availability.new
  end

  describe '#for_aliada' do
    it 'returns an aliada availability with a key' do
      @aliadas_availability.add('key', @first_five_schedules, aliada.id)

      availability = @aliadas_availability.for_aliada(aliada)

      expect(availability.aliada).to eql aliada
    end

    it 'adds schedules with the same aliada id as the availabilitys' do
      @aliadas_availability.add('key', @first_five_schedules, aliada.id)

      aliada_availability = @aliadas_availability.for_aliada(aliada)

      expect(aliada_availability.schedules_intervals.first.aliada_id).to eql aliada.id
    end
  end

  describe '#add' do
    it 'adds schedules' do
      @aliadas_availability.add('key', @first_five_schedules, aliada.id)

      expect(@aliadas_availability.schedules.map(&:id)).to eql @first_five_schedules.map(&:id)
    end

    it 'adds schedules one time unique by key' do
      @aliadas_availability.add('key', @first_five_schedules, aliada.id)
      @aliadas_availability.add('key', @last_five_schedules, aliada.id)

      expect(@aliadas_availability.size).to eql 1
      expect(@aliadas_availability.schedules.map(&:id)).to eql @first_five_schedules.map(&:id)
    end

    it 'converts schedules to schedules intervals' do
      @aliadas_availability.add('key', @first_five_schedules, aliada.id)

      expect(@aliadas_availability.schedules_intervals.first.class).to eql ScheduleInterval
    end
  end
end

