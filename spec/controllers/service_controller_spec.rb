feature 'ServiceController' do
  let!(:zone) { create(:zone) }
  let!(:service_type) { create(:service_type) }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              code: '11800') }
  context '#new' do
    it 'should be possible to create a new service' do
      expect(Address.all.count).to be 0
      expect(Service.all.count).to be 0

      with_rack_test_driver do
        page.driver.submit :post, new_service_path, {postal_code_id: postal_code.id}
      end

      fill_in 'Billable hours', with: '1'
      fill_in 'Bathrooms', with: '1'
      fill_in 'Bedrooms', with: '1'
      fill_in 'Aliada entry instruction', with: 'llaves con el portero'
      fill_in 'Cleaning products instruction', with: 'se le proveeran'
      fill_in 'Cleaning utensils instruction', with: 'bajo la tarja'
      fill_in 'Trash location instruction', with: 'en el patio'
      fill_in 'Special attention instruction', with: 'barrer patio'
      fill_in 'Special equipment instruction', with: 'encerar piso de madera'
      fill_in 'Do not touch instruction', with: 'no tocar la computadora'
      fill_in 'Special instructions', with: 'nada'
      fill_in 'Address', with: 'Calle de las aliadas'
      fill_in 'Number', with: '1' 
      fill_in 'Interior number', with: '2' 
      fill_in 'Between streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'Colony', with: 'Roma' 
      fill_in 'State', with: 'DF' 
      fill_in 'Municipality', with: 'Benito Juarez' 

      click_button 'Crear servicio'

      address = Address.first
      service = Service.first

      expect(current_path).to eq show_service_path(service.id)
      expect(address.address).to eql 'Calle de las aliadas'
      expect(address.number).to eql 1
      expect(address.interior_number).to eql 2
      expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
      expect(address.colony).to eql 'Roma'
      expect(address.state).to eql 'DF'
      expect(address.municipality).to eql 'Benito Juarez'
      expect(service.zone_id).to eql zone.id

      expect(service.billable_hours).to eql 1
      expect(service.bathrooms).to eql 1
      expect(service.bedrooms).to eql 1
      expect(service.aliada_entry_instruction).to eql 'llaves con el portero'
      expect(service.cleaning_products_instruction).to eql 'se le proveeran'
      expect(service.cleaning_utensils_instruction).to eql 'bajo la tarja'
      expect(service.trash_location_instruction).to eql 'en el patio'
      expect(service.special_attention_instruction).to eql 'barrer patio'
      expect(service.special_equipment_instruction).to eql 'encerar piso de madera'
      expect(service.do_not_touch_instruction).to eql 'no tocar la computadora'
      expect(service.special_instructions).to eql 'nada'
    end
  end
end
