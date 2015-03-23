feature 'ConektaCardsController' do
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let(:token){ 'tok_test_visa_4242' }
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 

  context 'on the user profile' do
    it 'lets the user add another card' do
      expect(user.payment_provider_choices).to be_empty
      login_as(user)

      visit(edit_users_path(user))
      fill_hidden_input 'conekta_temporary_token', with: token

      # TODO use regex matchers because the request wont match if the id of the generated card changes
      # and the cassette has the ids hardcoded in the request URI
      VCR.use_cassette('new_card', match_requests_on: [:conekta_charge]) do
        click_button 'Guardar Tarjeta'
      end

      new_conekta_card = ConektaCard.first

      expects_it_to_be_complete_and_valid(new_conekta_card)

      user.reload
      expect(user.payment_provider_choices.first.provider).to eql new_conekta_card
      expect(user.default_payment_provider).to eql new_conekta_card
    end
  end
end
