describe 'ConektaCard' do
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let!(:card){ create(:conekta_card) } 
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 
  let(:token){ 'tok_test_visa_4242' }
  let(:fake_product){ double(price: 300,
                             description: 'fake test product',
                             id: 1)}


  context 'offline testing' do
    it 'updates itself from a conekta customer' do
      VCR.use_cassette('conekta_customer') do
        card.create_customer(user, token)

        expects_it_to_be_complete_and_valid(card)
      end
    end

    it 'creates a charge' do
      VCR.use_cassette('conekta_charge') do
        card.token = token

        conekta_charge = card.charge!(fake_product,user)
        charge = eval(conekta_charge.inspect)

        expect(charge['amount']).to eql 30000
        expect(charge['status']).to eql 'paid'
        expect(charge['livemode']).to eql false
        expect(charge['object']).to eql 'charge'
        expect(charge['reference_id']).to eql '1'
        expect(charge['description']).to eql 'fake test product'
      end
    end

    it 'creates another card for user' do
      expect(user.payment_provider_choices).to be_empty
      expect(ConektaCard.first).to eql card

      # TODO use regex matchers because the request wont match if the id of the generated card changes
      VCR.use_cassette('new_card', match_requests_on: [:conekta_preauthorization]) do
        ConektaCard.create_for_user!(user, token)
      end

      new_conekta_card = ConektaCard.second

      expect(new_conekta_card).to_not eql card
      expects_it_to_be_complete_and_valid(new_conekta_card)

      expect(user.reload.payment_provider_choices.first.provider).to eql new_conekta_card
    end
  end
end
