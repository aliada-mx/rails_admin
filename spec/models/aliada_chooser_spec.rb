describe 'AliadaChooser' do
  include TestingSupport::SchedulesHelper

  describe '#choose' do
    let(:starting_datetime) { Time.zone.parse('01 Jan 2015 16:00:00') }
    let!(:user) { create(:user) }
    let!(:zone_1) { create(:zone) }
    let!(:zone_2) { create(:zone) }
    let!(:aliada_1) { create(:aliada, created_at: starting_datetime - 3.hours) }
    let!(:aliada_2) { create(:aliada, created_at: starting_datetime - 2.hours) }
    let!(:aliada_3) { create(:aliada, created_at: starting_datetime - 1.hour) }
    let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
    let!(:one_time_service_type) { create(:service_type, name: 'one-time') }
    let!(:recurrent_service_type) { create(:service_type, name: 'recurrent') }
    let!(:address_1){ create(:address)}
    let!(:service_1){ create(:service,
                             user: user,
                             recurrence: recurrence,
                             zone: zone_1,
                             service_type: one_time_service_type,
                             datetime: starting_datetime,
                             estimated_hours: 3,
                             address: address_1) }

    before :each do
      Timecop.freeze(starting_datetime-1.hour)

      create_recurrent!(starting_datetime-1.hour, hours: 5, periodicity: 7, conditions: {aliada_id: aliada_1.id, zone_id: zone_1.id})
      create_recurrent!(starting_datetime-1.hour, hours: 5, periodicity: 7, conditions: {aliada_id: aliada_2.id, zone_id: zone_1.id})
      create_recurrent!(starting_datetime-1.hour, hours: 5, periodicity: 7, conditions: {aliada_id: aliada_3.id, zone_id: zone_1.id})

      @aliadas_availability = AvailabilityForService.find_aliadas_availability(service_1)
    end

    after :each do
      Timecop.return
    end

    context '#sort_candidates' do
      after do
        chooser = AliadaChooser.new(@aliadas_availability, service_1)
        chooser.choose!

        expect(chooser.aliadas.map(&:id)).to eql [aliada_1.id, aliada_2.id, aliada_3.id]
      end

      it 'puts on top of the list the busiest aliada' do
        create(:service, aliada_id: aliada_1.id, datetime: starting_datetime + 5.day)
        create(:service, aliada_id: aliada_1.id, datetime: starting_datetime + 6.day)
        create(:service, aliada_id: aliada_1.id, datetime: starting_datetime + 7.day)
        create(:service, aliada_id: aliada_1.id, datetime: starting_datetime + 8.day)

        create(:service, aliada_id: aliada_2.id, datetime: starting_datetime + 2.day)
        create(:service, aliada_id: aliada_2.id, datetime: starting_datetime + 3.day)
        create(:service, aliada_id: aliada_2.id, datetime: starting_datetime + 4.day)

        create(:service, aliada_id: aliada_3.id, datetime: starting_datetime + 1.day)
      end

      it 'puts on top of the list the aliadas with a previous service on the same zone as the requested' do
        create(:service, aliada_id: aliada_1.id, datetime: starting_datetime - 5.hours, zone: zone_1)
        create(:service, aliada_id: aliada_2.id, datetime: starting_datetime - 5.hours, zone: zone_1)
        create(:service, aliada_id: aliada_3.id, datetime: starting_datetime - 5.hours, zone: zone_2)
      end

      it 'puts on top of the list the aliada with best qualifications' do
        create(:score, aliada_id: aliada_1.id, value: 5)
        create(:score, aliada_id: aliada_2.id, value: 4)
        create(:score, aliada_id: aliada_3.id, value: 3)
      end

      it 'among new aliadas without services or scores it sorts them by seniority' do
      end
    end
  end
end
