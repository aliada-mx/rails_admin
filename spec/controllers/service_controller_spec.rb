feature 'ServiceController' do
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

  context '#new' do
    it 'creates a new service' do
      expect(Address.all.count).to be 0
      expect(Service.all.count).to be 0
      expect(User.all.count).to be 0
      expect(Aliada.all.count).to be 1

      with_rack_test_driver do
        page.driver.submit :post, new_service_path, {postal_code_id: postal_code.id}
      end

      fill_in 'service_billable_hours', with: '1'
      fill_in 'service_bathrooms', with: '1'
      fill_in 'service_bedrooms', with: '1'

      check 'service_extra_ids_1'

      fill_in 'service_special_instructions', with: 'nada'
      fill_in 'service_address_street', with: 'Calle de las aliadas'
      fill_in 'service_address_number', with: '1' 
      fill_in 'service_address_interior_number', with: '2' 
      fill_in 'service_address_between_streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'service_address_colony', with: 'Roma' 
      fill_in 'service_address_state', with: 'DF' 
      fill_in 'service_address_city', with: 'Benito Juarez' 

      fill_in 'service_user_first_name', with: 'Guillermo' 
      fill_in 'service_user_last_name', with: 'Siliceo' 
      fill_in 'service_user_email', with: 'guillermo.siliceo@gmail.com' 
      fill_in 'service_user_phone', with: '5585519954' 

      choose "service_payment_method_id_#{payment_method.id}"
      choose "service_service_type_id_#{one_time_service.id}"

      fill_in 'service_date', with: 'Benito Juarez' 
      fill_in 'service_time', with: 'Benito Juarez' 

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
      expect(service.billable_hours).to eql 1
      expect(service.bathrooms).to eql 1
      expect(service.bedrooms).to eql 1
      expect(service.special_instructions).to eql 'nada'
      expect(service.payment_method_id).to eql payment_method.id
      expect(service.service_type_id).to eql one_time_service.id

      expect(user.first_name).to eql 'Guillermo'
      expect(user.last_name).to eql 'Siliceo'
      expect(user.email).to eql 'guillermo.siliceo@gmail.com'
      expect(user.phone).to eql '5585519954'
    end

    context 'logged in users' do
      let!(:user) { create(:user, 
                           first_name: 'Alex',
                           email: 'alex@aliada.mx',
                           last_name: 'Teutli',
                           phone: '01800-Aliado')}
      let!(:address){ create(:address, user: user, postal_code: postal_code)}

      before :each do
        login_as(user)

        with_rack_test_driver do
          page.driver.submit :post, new_service_path, {postal_code_id: postal_code.id}
        end
      end

      it 'shows them their saved data' do
        expect(page).to have_field 'service_user_first_name', with: 'Alex'
        expect(page).to have_field 'service_user_last_name', with: 'Teutli'
        expect(page).to have_field 'service_user_email', with: 'alex@aliada.mx'
        expect(page).to have_field 'service_user_phone', with: '01800-Aliado'
      end

      it 'allows them to update it' do
        fill_in 'service_user_first_name', with: 'Alejandro'
        fill_in 'service_user_last_name', with: 'Teu'
        fill_in 'service_user_email', with: 'alejandro@aliada.mx'
        fill_in 'service_user_phone', with: '01800-Aliado-yay'
        
        click_button 'Confirmar servicio'

        user.reload
        expect(user.first_name).to eql 'Alejandro'
        expect(user.last_name).to eql 'Teu'
        expect(user.email).to eql 'alejandro@aliada.mx'
        expect(user.phone).to eql '01800-Aliado-yay'
      end
    end
  end
end
