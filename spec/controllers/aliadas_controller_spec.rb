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
                         datetime: starting_datetime,
                         billable_hours: 3) }
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end


  describe '#services' do
    it 'checks the aliada is signed in' do
      aliada = create(:aliada)
      address1 = create(:address, city: 'Mexico',
                       street: 'Tabasco', number: '232', 
                       interior_number: 'torre A 802',
                       between_streets: 'colima y tonala',
                       colony: 'Roma Norte',
                       state: 'DF',
                       latitude: 19.98,
                       longitude: 20.45)
      address2 = create(:address, city: 'Mexico',
                       street: 'Tamal', number: '32', 
                       interior_number: '802',
                       between_streets: 'Insurgentes',
                       colony: 'Doctores',
                       state: 'DF',
                       latitude: 19.99,
                       longitude: 20.45) 
      Servicio1 = create(:service, aliada_id: aliada.id, address_id: address1.id)
      Servicio2 = create(:service, aliada_id: aliada.id, address_id: address2.id)
      #login_as(user)

      visit  ('aliadas/servicios/'+ aliada.authentication_token)
      save_and_open_page
      page.has_content?('Tus servicios')
    end
    
    it 'Shows message if token invalid' do
      visit  ('aliadas/servicios/'+ user.authentication_token)
      page.has_content?('Ruta invalida')
    end
  end
end
