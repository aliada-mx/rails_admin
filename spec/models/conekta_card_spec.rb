describe 'ConektaCard' do
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let!(:card){ create(:conekta_card) } 
  let!(:user){ create(:user, phone: '123456', first_name: 'Test', last_name: 'User', email: 'user-39@aliada.mx') } 
  let(:token){ 'tok_test_visa_4242' }
  let(:fake_product){ double(price_for_conekta: 3000,
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

        conekta_charge = card.charge!(fake_product)
        charge = eval(conekta_charge.inspect)

        expect(charge['amount']).to eql 3000
        expect(charge['status']).to eql 'paid'
        expect(charge['livemode']).to eql false
        expect(charge['object']).to eql 'charge'
        expect(charge['reference_id']).to eql '1'
        expect(charge['description']).to eql 'fake test product'
      end
    end
  end
end
