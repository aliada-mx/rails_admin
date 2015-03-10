# -*- coding: utf-8 -*-
feature 'ServiceController' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::SchedulesHelper
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrent_service) { create(:service_type) }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              number: '11800') }
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:extra_2){ create(:extra, name: 'Limpieza de refri')}
  let!(:conekta_card){ create(:payment_method)}
    
  before do
    allow_any_instance_of(Service).to receive(:timezone).and_return('UTC')
  end

  describe '#initial' do
    before do
      Timecop.freeze(starting_datetime)

      # The - 1 hour is needed because this hour is the one the aliada needs to get there from a previous service
      create_recurrent!(starting_datetime + 1.day - 1.hour, hours: 5, periodicity: recurrent_service.periodicity ,conditions: {zone: zone, aliada: aliada}, timezone: 'UTC')

      expect(Address.count).to be 0
      expect(Service.count).to be 0
      expect(IncompleteService.count).to be 0
      expect(Aliada.count).to be 1

      # We have hidden elements in our initial service creation assitant 
      # because we don't show all the steps at once
      @default_capybara_ignore_hidden_elements_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false

      visit initial_service_path
    end

    after do
      Timecop.return
      Capybara.ignore_hidden_elements = @default_capybara_ignore_hidden_elements_value
    end

    it 'redirects the logged in user to new service' do
      user = create(:user)

      login_as(user)
      visit initial_service_path

      expect(current_path).to eql new_service_users_path(user)
    end

    # We have separate tests that uses VCR for the payment logic
    context 'Skipping the payment logic' do
      before :each do
        expect(User.where('role != ?', 'aliada').count).to be 0
        expect(Schedule.available.count).to be 25

        User.any_instance.stub(:create_payment_provider!).and_return(nil)
        User.any_instance.stub(:ensure_first_payment!).and_return(nil)

        expect(current_path).to eq initial_service_path
      end

      after :each do
        expect(IncompleteService.count).to be 1
        incomplete_service = IncompleteService.first

        service = Service.first
        address = service.address
        user = service.user
        extras = service.extras
        service_aliada = service.aliada

        expect(service).to be_present
        expect(incomplete_service.service).to eql service

        expect(address.postal_code.number).to eql '11800'

        expect(service_aliada).to eql aliada
        expect(extras).to include extra_1

        expect(address.street).to eql 'Calle de las aliadas'
        expect(address.number).to eql "1"
        expect(address.interior_number).to eql "2"
        expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
        expect(address.colony).to eql 'Roma'
        expect(address.state).to eql 'DF'
        expect(address.city).to eql 'Benito Juarez'

        expect(service.zone_id).to eql zone.id
        expect(service.estimated_hours).to eql 3
        expect(service.bathrooms).to eql 1
        expect(service.bedrooms).to eql 1

        expect(service.special_instructions).to eql 'Algo especial'
        expect(service.garbage_instructions).to eql 'Algo de basura'
        expect(service.attention_instructions).to eql 'al perrito'
        expect(service.equipment_instructions).to eql 'con pinol mis platos'
        expect(service.forbidden_instructions).to eql 'no tocar mi colección de amiibos'
        expect(service.entrance_instructions).to eql true

        expect(user.first_name).to eql 'Guillermo'
        expect(user.last_name).to eql 'Siliceo'
        expect(user.email).to eql 'guillermo.siliceo@gmail.com'
        expect(user.phone).to eql '5585519954'
        expect(user.default_address).to eql address

      end

      it 'creates a new one time service' do
        fill_service_form(conekta_card, one_time_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        service = Service.first
        expect(service).to be_present

        expect(service.service_type_id).to eql one_time_service.id
        expect(Schedule.available.count).to be 21
        expect(Schedule.booked.count).to be 4
      end

      it 'creates a new recurrent service' do
        fill_service_form(conekta_card, recurrent_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        service = Service.first
        expect(service).to be_present

        user = service.user
        recurrence = service.recurrence
        recurrence.aliada = recurrence.aliada

        expect(recurrence.aliada).to eql aliada
        expect(recurrence.user).to eql user
        expect(recurrence.owner).to eql 'user'
        expect(recurrence.hour).to eql service.beginning_datetime.hour
        expect(recurrence.weekday).to eql service.beginning_datetime.weekday

        expect(service.service_type_id).to eql recurrent_service.id
        expect(Schedule.available.count).to be 5
        expect(Schedule.booked.count).to be 20
      end

      it 'logs in the new user' do
        fill_service_form(conekta_card, one_time_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        service = Service.first
        user = service.user

        next_services = next_services_users_path(user)

        visit next_services

        expect(current_path).to eql next_services
      end
    end

    context 'with real payment method' do
      before do
        expect(User.count).to be 0
        expect(Payment.count).to be 0
        expect(ConektaCard.count).to be 0
        expect(PaymentProviderChoice.count).to be 0
      end

      it 'creates a pre-authorization payment when choosing conekta' do
        fill_service_form(conekta_card, one_time_service, starting_datetime, extra_1, zone)

        fill_hidden_input 'conekta_temporary_token', with: 'tok_test_visa_4242'

        VCR.use_cassette('initial_service_conekta_card', match_requests_on: [:method, :conekta_preauthorization]) do
          click_button 'Confirmar visita'
        end

        payment = Payment.first
        conekta_card = ConektaCard.first
        payment_provider_choice = PaymentProviderChoice.first
        user = User.first

        expect(Payment.count).to be 1
        expect(ConektaCard.count).to be 1
        expect(PaymentProviderChoice.count).to be 1
        expect(User.count).to be 1

        expect(payment.provider).to eql conekta_card
        expect(payment.user).to eql user
        expect(payment.amount).to eql 3
        expect(payment).to be_paid

        expects_it_to_be_complete_and_valid(conekta_card)
        expect(conekta_card).to be_preauthorized

        expect(payment_provider_choice.user).to eql user
        expect(payment_provider_choice).to eql payment_provider_choice
        expect(payment_provider_choice.provider).to eql conekta_card
      end
    end
  end

  context 'created users' do
    let(:admin){ create(:admin) }
    let(:user){ create(:user) }
    let(:address){ create(:address, postal_code: postal_code) }
    let(:service){ create(:service, 
                          aliada: aliada,
                          user: user,
                          service_type: one_time_service) }
    let(:admin_service){ create(:service, 
                                aliada: aliada,
                                user: admin,
                                service_type: one_time_service) }

    describe '#edit' do
      it 'lets the admin edit any user services' do
        login_as(admin)

        edit_service_path = edit_service_users_path(user_id: user.id, service_id: service.id)

        visit edit_service_path
        
        expect(page.current_path).to eql edit_service_path
      end

      it 'doesnt let the user edit other users services' do
        login_as(user)

        edit_service_path = edit_service_users_path(user_id: admin.id, service_id: admin_service.id)

        visit edit_service_path
        
        expect(page.current_path).not_to eql edit_service_path
      end

      it 'let the user edit its own services' do
        login_as(user)

        edit_service_path = edit_service_users_path(user_id: user.id, service_id: user.id)

        visit edit_service_path
        
        expect(page.current_path).to eql edit_service_path
      end
    end

    describe '#new' do
      it 'let the user view the new service page' do
        login_as(user)

        new_service_path = new_service_users_path(user)

        visit new_service_path
        
        expect(page.current_path).to eql new_service_path
      end
    end
  end
end

