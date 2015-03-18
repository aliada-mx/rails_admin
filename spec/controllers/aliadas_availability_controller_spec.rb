feature 'AliadasAvailabilityController' do
  include TestingSupport::SchedulesHelper
  
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }
  let(:one_time){ create(:service_type, name: 'one-time') }
  let(:aliada){ create(:aliada) }
  let(:aliada_2){ create(:aliada) }
  let(:zone){ create(:zone) }
  let(:postal_code){ create(:postal_code, :zoned, zone: zone) }
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 
  let!(:service){ create(:service, user: user) }

  before do
    create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada, zones: [zone]})
    create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada_2, zones: [zone]})
    Timecop.freeze(starting_datetime)

    booked_interval = create_one_timer!(starting_datetime + 2.day, hours: 5, conditions: {aliada: aliada, zones: [zone], service: service, status: 'booked'} )
    @booked_schedules = booked_interval.schedules
  end

  after do
    Timecop.return
  end

  describe 'for_calendar' do
    context 'user selected one time service' do
      it 'returns a json with dates times included' do

        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 3, service_type_id: one_time.id, postal_code_number: postal_code.number}
        end
        
        response = JSON.parse(page.body)
        available_date = (starting_datetime + 1.day).strftime('%Y-%m-%d')
        expect(response['dates_times'].has_key?(available_date)).to eql true
        expect(response['dates_times'][available_date]).to eql [{"value" => "07:00","friendly_time" => " 7:00 am", "friendly_datetime"=>"viernes 02 de enero,  7:00 am"}]
      end

      it 'returns a json with dates times including the passed service availability' do
        login_as(user)

        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 3, service_type_id: one_time.id, postal_code_number: postal_code.number, service_id: service.id}
        end
        
        response = JSON.parse(page.body)
        available_date = (starting_datetime + 1.day).strftime('%Y-%m-%d')
        service_available_date = (starting_datetime + 2.day).strftime('%Y-%m-%d')

        expect(response['dates_times'].has_key?(available_date)).to eql true
        expect(response['dates_times'][available_date]).to eql [{"value" => "07:00","friendly_time" => " 7:00 am", "friendly_datetime"=>"viernes 02 de enero,  7:00 am"}]
        expect(response['dates_times'][service_available_date]).to eql [{"value"=>"07:00", "friendly_time"=>" 7:00 am", "friendly_datetime"=>"sábado 03 de enero,  7:00 am"}]
      end
    end
  end

  describe '#find_availability' do
    it 'filters by passed aliada id' do
      @controller = AliadasAvailabilityController.new
      availability = @controller.send(:find_availability, 3,  zone, starting_datetime, aliada.id, one_time)

      aliadas_ids = availability.schedules.map { |schedule| schedule.aliada_id }

      expect(aliadas_ids).to include aliada.id
      expect(aliadas_ids).not_to include aliada_2.id
    end
  end
end
