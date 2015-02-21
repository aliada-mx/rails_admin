describe 'AliadaAvailability' do
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
                                   billed_hours: 3,
                                   address: address_1) }
  let!(:recurrent_service){ create(:service,
                                   user: user,
                                   recurrence: recurrence,
                                   zone: zone_1,
                                   service_type: recurrent_service_type,
                                   datetime: starting_datetime,
                                   billed_hours: 3,
                                   address: address_1) }

  context 'For a one time service' do
    before do
      create_one_timer!(starting_datetime, hours: 5, conditions: {aliada_id: aliada.id, zone_id: zone_1.id})
      @first_five_schedules = Schedule.all.limit(5)
      @last_five_schedules = Schedule.all.where('id not in (?)', @first_five_schedules.map(&:id))

      @aliadas_availability = AliadaAvailability.new(one_time_service)
    end

    describe '#add' do
      it 'adds schedules if there is enough of them' do
        @aliadas_availability.add(aliada.id, [@first_five_schedules])

        expect(@aliadas_availability.schedules.map(&:id)).to eql @first_five_schedules.map(&:id)
      end

      it 'doesnt add schedules if there are too many' do
        @aliadas_availability.add(aliada.id, [@first_five_schedules])
        @aliadas_availability.add(aliada.id, [@last_five_schedules])

        expect(@aliadas_availability.schedules.map(&:id)).to eql @first_five_schedules.map(&:id)
      end
    end
  end

  context 'For a recurrent service' do
    before do
      @recurrent_intervals = create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada_id: aliada.id, zone_id: zone_1.id})
      @first_intervals = @recurrent_intervals.first
      @second_intervals = @recurrent_intervals.second
      @third_intervals = @recurrent_intervals.third
      @fourth_intervals = @recurrent_intervals.fourth

      @aliadas_availability = AliadaAvailability.new(recurrent_service)
    end

    describe '#add' do
      it 'adds intervals if there is enough of them' do
        @aliadas_availability.add(aliada.id, [@first_intervals])

        expect(@aliadas_availability.schedules).to eql @first_intervals.schedules
      end

      it 'doesnt add intervals they are no continuous' do
        @aliadas_availability.add(aliada.id, [@first_intervals])
        expect(@aliadas_availability.schedules).to eql @first_intervals.schedules

        @aliadas_availability.add(aliada.id, [@second_intervals])
        expect(@aliadas_availability.schedules).to eql @first_intervals.schedules + @second_intervals.schedules

        @aliadas_availability.add(aliada.id, [@fourth_intervals])
        expect(@aliadas_availability.schedules).to eql []
      end
    end
  end
end

