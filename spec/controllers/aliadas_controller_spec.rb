feature 'AliadasController' do
  
 
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
                         datetime: starting_datetime 
                         #billable_hours: 3
) }
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
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
                       longitude: 20.45) 
      Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: DateTime.now
                         )
      Servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: DateTime.now)
      #login_as(user)
  
      visit  ('aliadas/servicios/'+ aliada.authentication_token)
      save_and_open_page
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
                       longitude: 20.45) 
      Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id,
                         bathrooms: 2,
                         bedrooms: 3,
                         user_id: client.id, datetime: (DateTime.now+1)
                         )
      Servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id,
                         user_id: client.id, datetime: DateTime.now)
      #login_as(user)
      Timecop.freeze(Date.today + 1) do
         visit  ('aliadas/servicios/'+ aliada.authentication_token)
        save_and_open_page
        expect(page).to   have_content 'Roma Norte'
      end
  
     
    end
    
    
    it 'Shows message if token invalid' do
      visit  ('aliadas/servicios/'+ user.authentication_token)
      page.has_content?('Ruta invalida')
    end
  end
end
