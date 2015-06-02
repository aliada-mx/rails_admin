# -*- encoding : utf-8 -*-
describe 'ConektaCard' do
  include TestingSupport::SharedExpectations::ConektaCardExpectations
  let!(:card){ create(:conekta_card) } 
  let!(:service){ create(:service) }
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 
  let(:token){ 'tok_test_visa_4242' }
  let(:service){ double(amount: 300,
                        description: 'fake test service',
                        id: 1)}


  context 'offline testing' do
    it 'updates itself from a conekta customer' do
      VCR.use_cassette('conekta_customer') do
        card.create_customer(user, token)

        expects_it_to_be_complete_and_valid(card)
      end
    end

    it 'charge_in_conekta' do
      VCR.use_cassette('conekta_charge') do
        card.token = token
        
        conekta_charge = card.charge_in_conekta!(service,user)
        charge = eval(conekta_charge.inspect)

        expect(charge['amount']).to eql 30000
        expect(charge['status']).to eql 'paid'
        expect(charge['livemode']).to eql false
        expect(charge['object']).to eql 'charge'
        expect(charge['reference_id']).to eql '1'
        expect(charge['description']).to eql 'fake test service'
      end
    end

    it 'creates another card for user' do
      allow_any_instance_of(ConektaCard).to receive(:refund).and_return(true)

      expect(user.payment_provider_choices).to be_empty
      expect(ConektaCard.first).to eql card

      # TODO use regex matchers because the request wont match if the id of the generated card changes
      VCR.use_cassette('new_card', match_requests_on: [:conekta_charge]) do
        ConektaCard.create_for_user!(user, token, service)
      end

      new_conekta_card = ConektaCard.second

      expect(new_conekta_card).to_not eql card
      expects_it_to_be_complete_and_valid(new_conekta_card)

      expect(user.reload.payment_provider_choices.first.provider).to eql new_conekta_card
    end

    it 'preauthorizes a card' do
      card.token = token
      expect(card).not_to be_preauthorized

      VCR.use_cassette('preauthorize', match_requests_on: [ :conekta_charge ]) do
        card.preauthorize!(user, service)
      end

      card.reload
      expect(card).to be_preauthorized
    end
  end
end
