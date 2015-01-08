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
      expect(address.address).to eql 'Calle de las aliadas'
      expect(address.number).to eql 1
      expect(address.interior_number).to eql 2
      expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
      expect(address.colony).to eql 'Roma'
      expect(address.state).to eql 'DF'
      expect(address.municipality).to eql 'Benito Juarez'
      expect(service.zone_id).to eql zone.id
    end
  end
end
