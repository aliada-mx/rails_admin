feature 'ServiceController' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::SchedulesHelper

  starting_datetime = Time.zone.now.change({hour: 13})
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrent_service) { create(:service_type) }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              code: '11800') }
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:extra_2){ create(:extra, name: 'Limpieza de refri')}
  let!(:payment_method){ create(:payment_method)}

  before do
    Timecop.freeze(starting_datetime)

    create_recurrent!(starting_datetime, hours: 5, periodicity: recurrent_service.periodicity ,conditions: {zone: zone, aliada: aliada})

    expect(Address.all.count).to be 0
    expect(Service.all.count).to be 0
    expect(Aliada.all.count).to be 1
  end

  after do
    Timecop.return
  end

  context '#initial' do
    it 'redirects the logged in user to new service' do
      user = create(:user)

      login_as(user)
      with_rack_test_driver do
        page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
      end
      
      expect(current_path).to eq new_service_path
    end

    it 'creates a new one time service' do
      with_rack_test_driver do
        page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
      end
      expect(User.where('role != ?', 'aliada').count).to be 0
      expect(Schedule.available.count).to be 20

      fill_service_form(payment_method, one_time_service, starting_datetime, extra_1)

      click_button 'Confirmar servicio'

      service = Service.first
      address = service.address
      user = service.user
      extras = service.extras

      expect(extras).to include extra_1

      expect(current_path).to eq show_service_path(service.id)

      expect(address.street).to eql 'Calle de las aliadas'
      expect(address.number).to eql 1
      expect(address.interior_number).to eql 2
      expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
      expect(address.colony).to eql 'Roma'
      expect(address.state).to eql 'DF'
      expect(address.city).to eql 'Benito Juarez'

      expect(service.zone_id).to eql zone.id
      expect(service.billable_hours).to eql 3
      expect(service.bathrooms).to eql 1
      expect(service.bedrooms).to eql 1
      expect(service.special_instructions).to eql 'nada'
      expect(service.payment_method_id).to eql payment_method.id
      expect(service.service_type_id).to eql one_time_service.id

      expect(user.first_name).to eql 'Guillermo'
      expect(user.last_name).to eql 'Siliceo'
      expect(user.email).to eql 'guillermo.siliceo@gmail.com'
      expect(user.phone).to eql '5585519954'

      expect(Schedule.available.count).to be 15
      expect(Schedule.booked.count).to be 5
    end

    it 'creates a new recurrent service' do
      with_rack_test_driver do
        page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
      end

      expect(User.where('role != ?', 'aliada').count).to be 0
      expect(Schedule.available.count).to be 20

      fill_service_form(payment_method, recurrent_service, starting_datetime, extra_1)

      click_button 'Confirmar servicio'

      service = Service.first
      address = service.address
      user = service.user
      extras = service.extras

      expect(extras).to include extra_1

      expect(current_path).to eq show_service_path(service.id)

      expect(address.street).to eql 'Calle de las aliadas'
      expect(address.number).to eql 1
      expect(address.interior_number).to eql 2
      expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
      expect(address.colony).to eql 'Roma'
      expect(address.state).to eql 'DF'
      expect(address.city).to eql 'Benito Juarez'

      expect(service.zone_id).to eql zone.id
      expect(service.billable_hours).to eql 3
      expect(service.bathrooms).to eql 1
      expect(service.bedrooms).to eql 1
      expect(service.special_instructions).to eql 'nada'
      expect(service.payment_method_id).to eql payment_method.id
      expect(service.service_type_id).to eql recurrent_service.id

      expect(user.first_name).to eql 'Guillermo'
      expect(user.last_name).to eql 'Siliceo'
      expect(user.email).to eql 'guillermo.siliceo@gmail.com'
      expect(user.phone).to eql '5585519954'

      expect(Schedule.available.count).to be 0
      expect(Schedule.booked.count).to be 20
    end
  end
end
