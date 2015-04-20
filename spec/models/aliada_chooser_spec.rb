# -*- encoding : utf-8 -*-
describe 'AliadaChooser' do
  include TestingSupport::SchedulesHelper

  describe '#choose' do
    let(:starting_datetime) { Time.zone.parse('01 Jan 2015 22:00:00') } # 4 pm on Mexico City TZ
    let!(:user) { create(:user) }
    let!(:zone_1) { create(:zone) }
    let!(:zone_2) { create(:zone) }
    let!(:aliada_1) { create(:aliada, created_at: starting_datetime - 3.hours, zones: [zone_1]) }
    let!(:aliada_2) { create(:aliada, created_at: starting_datetime - 2.hours, zones: [zone_1]) }
    let!(:aliada_3) { create(:aliada, created_at: starting_datetime - 1.hour, zones: [zone_1]) }
    let!(:one_time_service_type) { create(:service_type, name: 'one-time') }
    let!(:address_1){ create(:address)}
    let!(:service_1){ create(:service,
                             user: user,
                             zone: zone_1,
                             service_type: one_time_service_type,
                             timezone: 'Mexico City',
                             datetime: starting_datetime,
                             estimated_hours: 3,
                             address: address_1) }

    before :each do
      Timecop.freeze(starting_datetime)

      create_one_timer!(starting_datetime - 1.hour, hours: 5, conditions: {aliada_id: aliada_1.id})
      create_one_timer!(starting_datetime - 1.hour, hours: 5, conditions: {aliada_id: aliada_2.id})
      create_one_timer!(starting_datetime - 1.hour, hours: 5, conditions: {aliada_id: aliada_3.id})

      @aliadas_availability = AvailabilityForService.find_aliadas_availability(service_1, starting_datetime - 1.hour)
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
