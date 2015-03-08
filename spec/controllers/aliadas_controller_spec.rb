feature 'AliadasController' do
  
  let!(:conekta_card){ create(:conekta_card) }
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }
  let!(:user) { create(:user) }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrence){ create(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let!(:recurrent_service) { create(:service_type, name: 'recurrent') }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:service){ create(:service,
                         aliada: aliada,
                         user: user,
                         recurrence: recurrence,
                         zone: zone,
                         service_type: one_time_service,
                         datetime: starting_datetime, 
                         estimated_hours: 3
                         ) }
  before do
    # Capybara.current_driver = :webkit  
    Timecop.freeze(starting_datetime)
  end

  after do
    # Capybara.use_default_driver       
    Timecop.return
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
      Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: (DateTime.now+1)
                         )
      Servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: DateTime.now)
      visit  ('aliadas/servicios/'+ aliada.authentication_token)
      #save_and_open_page
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
      Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: (DateTime.now+1.day)
                         )
      Servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: DateTime.now)
      
      Timecop.freeze(Date.today + 1) do
        visit  ('aliadas/servicios/'+ aliada.authentication_token)
        #  save_and_open_page
        expect(page).to   have_content 'Roma Norte'
      end
      
      
    end 
    
    it 'shows unfinished services and lets us charge them' do
      aliada = create(:aliada)
      client = create(:user, phone: '54545454', first_name: 'Juan', last_name:'Perez Tellez')
      VCR.use_cassette('conekta_charge', match_requests_on: [:conekta_preauthorization]) do
        client.create_payment_provider_choice(conekta_card)
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
        Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                           bathrooms: 2,
                           bedrooms: 3,
                           status: 'aliada_assigned',
                           service_type: one_time_service,
                           user_id: client.id, 
                           datetime: (DateTime.now-1))
        Servicio2 = create(:service, aliada_id: aliada.id+1, address_id: address2.id,
                           user_id: client.id, status: 'aliada_assigned', datetime: DateTime.now-1)
        visit  ('aliadas/servicios/'+ aliada.authentication_token)

        #   save_and_open_page
        page.has_content?('Tus servicios')
       #  save_and_open_page
        
        click_on('Pagar')
       # save_and_open_page
        expect(Payment.all.count).to be 1
      end
    end
    
    it 'Shows message if token invalid' do
      visit  ('aliadas/servicios/'+ user.authentication_token)
      page.has_content?('Ruta invalida')
    end
  end
end
