feature 'ServiceController' do
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
    it 'should be possible to create a new service' do
      expect(Address.all.count).to be 0
      expect(Service.all.count).to be 0

      with_rack_test_driver do
        page.driver.submit :post, new_service_path, {postal_code_id: postal_code.id}
      end

      fill_in 'service_billable_hours', with: '1'
      fill_in 'service_bathrooms', with: '1'
      check 'service_extra_ids_1'
      fill_in 'service_bedrooms', with: '1'
      fill_in 'service_special_instructions', with: 'nada'
      fill_in 'service_address_attributes_street', with: 'Calle de las aliadas'
      fill_in 'service_address_attributes_number', with: '1' 
      fill_in 'service_address_attributes_interior_number', with: '2' 
      fill_in 'service_address_attributes_between_streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'service_address_attributes_colony', with: 'Roma' 
      fill_in 'service_address_attributes_state', with: 'DF' 
      fill_in 'service_address_attributes_city', with: 'Benito Juarez' 
      choose "service_payment_method_id_#{payment_method.id}"
      choose "service_service_type_id_#{one_time_service.id}"

      click_button 'Confirmar servicio'

      address = Address.first
      service = Service.first
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
    end
  end
end
