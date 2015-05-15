# -*- encoding : utf-8 -*-
feature 'AliadasController' do
  let!(:conekta_card){ create(:conekta_card) }
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 14:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent') }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:service){ create(:service,
                         aliada: aliada,
                         status: 'aliada_assigned',
                         user: user,
                         recurrence: recurrence,
                         zone: zone,
                         service_type: one_time_service,
                         datetime: starting_datetime - 1.day, 
                         estimated_hours: 3
                         ) }
  before do
    Timecop.freeze(starting_datetime)
    allow_any_instance_of(Aliada).to receive(:track_webapp_view).and_return(nil)

    clear_session
  end

  after do
    Timecop.return
    clear_session
  end

  describe '#finish' do
    it 'saves the billable hours calculated with reported hours' do
      params = {
        hour: 3,
        min: 0,
        service: service.id,
      }

      with_rack_test_driver do
        page.driver.submit :post, finish_service_path(aliada.authentication_token), params
      end

      expect(service.reload.billable_hours).to eql 3
    end
  end
  
  describe '#services' do
    
    it 'checks the aliada has a valid token' do
      aliada = create(:aliada)
      client = create(:user, phone: '54545454', first_name: 'Juan', last_name:'Perez Tellez')
      address1 = create(:address, city: 'Cuauhtemoc',
                        street: 'Tabasco', number: '232', 
                        interior_number: 'torre A 802',
                        between_streets: 'colima y tonala',
                        colony: 'Roma Norte',
                        state: 'DF',
                        latitude: 19.98,
                        longitude: 20.45)
      address2 = create(:address, city: 'Coyoacan',
                        street: 'Tamales', number: '32', 
                        interior_number: '802',
                        between_streets: 'Insurgentes',
                        colony: 'Doctores',
                        state: 'DF',
                        latitude: 19.99,
                        references: 'Metro insurgentes',
                        references_latitude: 19.991,
                        references_longitude: 20.451,
                        map_zoom: 2,
                        longitude: 20.45) 
      servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: (DateTime.now+1)
                         )
      servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: DateTime.now)
      visit(aliadas_services_path(aliada.authentication_token))
      page.has_content?('Tus servicios')
    end

    it 'Shows tomorrows services if it is tommorrow' do
      aliada = create(:aliada)
      client = create(:user, phone: '54545454', first_name: 'Juan', last_name:'Perez Tellez')
      address1 = create(:address, city: 'Cuauhtemoc',
                        street: 'Tabasco', number: '232',  
                        interior_number: 'torre A 802',
                        between_streets: 'colima y tonala',
                        colony: 'Roma Norte',
                        references: 'Metro insurgentes',
                        state: 'DF',
                        references_latitude: 19.541,
                        references_longitude: -99.451,
                        map_zoom: 16,
                        latitude: 19.54,
                        longitude: -99.45)
      address2 = create(:address, city: 'Coyoacan',
                        street: 'Tamales', number: '32', 
                        interior_number: '802',
                        between_streets: 'Insurgentes',
                        colony: 'Doctores',
                        state: 'DF',
                        references: 'Metro insurgentes',
                        references_latitude: 19.541,
                        references_longitude: -99.451,
                        map_zoom: 16, 
                        latitude: 19.54,
                        longitude: -99.45) 
      servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: ActiveSupport::TimeZone['Mexico City'].parse('2015-09-04 17:00').utc
                         )
      servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: ActiveSupport::TimeZone['Mexico City'].parse('2015-09-03 17:00').utc)
      
      Timecop.freeze('2015-09-04 12:00') do
        visit(aliadas_services_path(aliada.authentication_token))

        expect(page).to   have_content 'Roma Norte'
        expect(page).to have_content 'Metro insurgentes'
        expect(page).to have_content 'Tabasco'
        expect(page).to have_content 'torre A 802'
        expect(page).to have_content 'Cuauhtemoc'
        expect(page).to have_content 'Juan'
      end
      
      
    end 
    
    it 'Shows message if token invalid' do
      visit(aliadas_services_path('invalid-token'))

      expect(page).to have_content('Ruta invalida')
    end

  end

  describe '#unassign' do
    let!(:service_to_confirm){ create(:service,
                           aliada: aliada,
                           status: 'aliada_assigned',
                           user: user,
                           recurrence: recurrence,
                           zone: zone,
                           service_type: one_time_service,
                           datetime: starting_datetime + 1.day, 
                           estimated_hours: 3
                           ) }
    before do
      Timecop.travel(starting_datetime + 10.hours)
    end

    it 'changes the service status' do
      visit(aliadas_services_path(aliada.authentication_token))

      click_on('No voy')

      service_to_confirm.reload
      expect(service_to_confirm).to be_aliada_missing
    end
  end

  describe '#worked_services' do

    it 'saves the worked hours on a service' do
      visit(aliadas_worked_services_path(aliada.authentication_token))

      select_by_value(3, from: "service_#{service.id}_hours")
      select_by_value(30, from: "service_#{service.id}_mins")

      click_on('Guardar')

      service.reload
      expect(service.hours_worked).to eql BigDecimal.new('3.5')
      expect(page).to have_content('3 horas 30 minutos')
    end
  end
end
