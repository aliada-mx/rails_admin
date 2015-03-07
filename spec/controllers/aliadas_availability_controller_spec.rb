feature 'AliadasAvailabilityController' do
  include TestingSupport::SchedulesHelper
  
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }
  let(:one_time){ create(:service_type, name: 'one-time') }
  let(:recurrent){ create(:service_type) }
  let(:aliada){ create(:aliada) }
  let(:zone){ create(:zone) }
  let(:postal_code){ create(:postal_code, :zoned, zone: zone) }
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 

  describe 'for_calendar' do
    context 'user selected one time service' do
      before do
        create_one_timer!(starting_datetime + 1.day, hours: 5, conditions: {aliada: aliada, zone: zone} )
        Timecop.freeze(starting_datetime)
      end

      after do
        Timecop.return
      end

      it 'returns a json with dates times included' do
        with_rack_test_driver do
          page.driver.submit :post, aliadas_availability_path, {hours: 3, service_type_id: one_time.id, postal_code_number: postal_code.number}
        end
        
        
        response = JSON.parse(page.body)
        available_date = (starting_datetime + 1.day).strftime('%Y-%m-%d')
        expect(response['dates_times'].has_key?(available_date)).to eql true
        expect(response['dates_times'][available_date]).to eql [{"value" => "07:00","friendly_time" => " 7:00 am"}]
      end
    end
  end
end
