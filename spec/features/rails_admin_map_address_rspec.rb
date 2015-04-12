# -*- encoding : utf-8 -*-
feature 'Change address map latitude' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::CapybaraHelpers

  let(:admin){ create(:admin) }

  let!(:user){ create(:user) }
  let!(:postal_code){ create(:postal_code, number: '11800') }
  let!(:address){ create(:address, user: user, postal_code: postal_code) }

  describe '#map_address' do
    context 'with actual jobs being run' do
      it 'changes the address attributes' do
        login_as(admin)

        visit rails_admin.address_map_path('Address', address.id)

        fill_in 'address_street', with: 'Calle de las aliadas'
        fill_in 'address_number', with: '1' 
        fill_in 'address_interior_number', with: '2' 
        fill_in 'address_between_streets', with: 'Calle de los aliados, calle de los bifes' 
        fill_in 'address_colony', with: 'Roma' 
        fill_in 'address_state', with: 'DF' 
        fill_in 'address_city', with: 'Benito Juarez' 
        fill_in 'address_postal_code_number', with: '11800'

        fill_hidden_input 'address_references_latitude', with: '11.11111'
        fill_hidden_input 'address_references_longitude', with: '11.11111'

        fill_hidden_input 'address_map_center_longitude', with: '22.2222'
        fill_hidden_input 'address_map_center_latitude', with: '22.2222'

        fill_hidden_input 'address_latitude', with: '33.3333'
        fill_hidden_input 'address_longitude', with: '33.3333'
        fill_hidden_input 'address_map_zoom', with: '9'

        click_button 'Guardar'

        expect_to_have_a_complete_address(address.reload)

        expect(address.references_latitude).to eql 11.11111
        expect(address.references_longitude).to eql 11.11111

        expect(address.map_center_longitude).to eql 22.2222
        expect(address.map_center_latitude).to eql 22.2222

        expect(address.latitude).to eql 33.3333
        expect(address.longitude).to eql 33.3333

        expect(address.map_zoom).to eql 9
      end
    end
  end
end
