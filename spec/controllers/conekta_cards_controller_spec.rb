# -*- encoding : utf-8 -*-
feature 'ConektaCardsController' do
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 14:00:00') }
  let(:token){ 'tok_test_visa_4242' }
  let!(:previous_conekta_card){ create(:conekta_card) } 
  let!(:user){ create(:user, 
                      phone: '123456',
                      first_name: 'Test',
                      last_name: 'User',
                      email: 'user-39@aliada.mx',
                      conekta_customer_id: "cus_M3V9nERCq9qDLZdD1") } 
  let!(:service){ create(:service, user: user, datetime: starting_datetime - 1.hour) }
  let!(:debt){ create(:debt, user: user, service: service) }

  context 'on the user profile' do
    before do
      allow_any_instance_of(User).to receive(:default_payment_provider).and_return(previous_conekta_card)
      allow_any_instance_of(User).to receive(:missing_payment_provider_choice?).and_return(false)
      allow_any_instance_of(ConektaCard).to receive(:refund).and_return(true)

      Timecop.freeze(starting_datetime)
      ResqueSpec.reset!

      clear_session
    end

    after do
      Timecop.return
    end

    # TODO enable when adding new cards feature is done
    it 'lets the user add another card' do
      expect(user.payment_provider_choices).to be_empty
      login_as(user)

      visit(edit_users_path(user))
      fill_hidden_input 'conekta_temporary_token', with: token

      # TODO use regex matchers because the request wont match if the id of the generated card changes
      # and the cassette has the ids hardcoded in the request URI
      VCR.use_cassette('new_card', match_requests_on: [:conekta_charge]) do
        click_button 'Guardar nueva tarjeta'
      end

      response = JSON.parse(page.body)
      expect(response['status']).to eql 'success'

      new_conekta_card = ConektaCard.find response['conekta_card_id']
      expect(new_conekta_card.id).not_to eql previous_conekta_card.id

      expects_it_to_be_complete_and_valid(new_conekta_card)

      expect_any_instance_of(User).to receive(:default_payment_provider).and_call_original
      user.reload
      expect(user.payment_provider_choices.first.provider).to eql new_conekta_card
      expect(user.default_payment_provider).to eql new_conekta_card
    end

    it 'enques charging services when adding a new card' do
      allow(ConektaCard).to receive(:create_for_user!).and_return(previous_conekta_card)

      login_as(user)

      with_rack_test_driver do
        page.driver.submit :post, create_conekta_card_users_path(user), {}
      end

      expect(ServiceCharger).to have_queued([ service.id ])
    end
  end
end
