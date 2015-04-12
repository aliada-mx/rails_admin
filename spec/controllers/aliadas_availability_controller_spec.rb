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

  describe 'for_calendar' do
    before do
      clear_session
      create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada, zones: [zone]})
      create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada_2, zones: [zone]})

      Timecop.freeze(starting_datetime)

      @available_date = (starting_datetime + 1.day).strftime('%Y-%m-%d')
    end

    after do
      Timecop.return
    end

    context 'user selected one time service' do
      it 'returns a json with dates times included' do

        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 4, service_type_id: one_time.id, postal_code_number: postal_code.number}
        end
        
        response = JSON.parse(page.body)
        expect(response['dates_times'].has_key?(@available_date)).to eql true
        expect(response['dates_times'][@available_date]).to eql [{"value" => "07:00","friendly_time" => " 7:00 am", "friendly_datetime"=>"02 de enero 2015,  7:00 am"}]
      end

      it 'returns a json without dates times if theres not availabilty' do
        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 5, service_type_id: one_time.id, postal_code_number: postal_code.number}
        end
        
        response = JSON.parse(page.body)
        expect(response['dates_times']).to be_empty
      end

      it 'returns a json with dates times including the passed service availability' do
        create_one_timer!(starting_datetime + 1.day + 4.hour, hours: 1, conditions: {aliada: aliada, 
                                                                                     zones: [zone],
                                                                                     service: service,
                                                                                     status: 'booked'} )
        login_as(user)

        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 5, service_type_id: one_time.id, postal_code_number: postal_code.number, service_id: service.id}
        end
        
        response = JSON.parse(page.body)

        expect(response['dates_times'].has_key?(@available_date)).to eql true
        expect(response['dates_times'][@available_date]).to eql [{"value" => "07:00","friendly_time" => " 7:00 am", "friendly_datetime"=>"02 de enero 2015,  7:00 am"}]
      end
    end

    context 'on CST time' do
      let(:cst_starting_datetime){ Time.zone.parse('04 Apr 2015 13:00:00').in_time_zone('Mexico City') }

      before do
        Timecop.freeze(cst_starting_datetime)

        create_one_timer!(cst_starting_datetime + 1.day + 1.hour, hours: 4, conditions: {aliada: aliada_2, zones: [zone]})
      end

      it 'return the time with -1 hour' do
        login_as(user)

        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, { hours: 4, service_type_id: one_time.id, postal_code_number: postal_code.number }
        end

        response = JSON.parse(page.body)

        expect(response['dates_times']["2015-04-05"]).to eql [{"value"=>"07:00", "friendly_time"=>" 7:00 am", "friendly_datetime"=>"05 de abril 2015,  7:00 am"}]
      end
    end
  end

  describe '#find_availability' do
    before do
      create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada, zones: [zone]})
      create_one_timer!(starting_datetime + 1.day, hours: 4, conditions: {aliada: aliada_2, zones: [zone]})

      Timecop.freeze(starting_datetime)

      @available_date = (starting_datetime + 1.day).strftime('%Y-%m-%d')
    end

    after do
      Timecop.return
    end

    it 'filters by passed aliada id' do
      @controller = AliadasAvailabilityController.new
      availability = @controller.send(:find_availability, 3,  zone, starting_datetime, aliada.id, one_time)

      aliadas_ids = availability.schedules.map { |schedule| schedule.aliada_id }

      expect(aliadas_ids).to include aliada.id
      expect(aliadas_ids).not_to include aliada_2.id
    end
  end
end
