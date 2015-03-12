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
        expect(service_aliada).to eql aliada
        expect(extras).to include extra_1
        expect(incomplete_service.service).to eql service

        expect_to_have_a_complete_service(service)

        expect_to_have_a_complete_address(address)

        expect_to_have_a_complete_user(user)

        expect(user.default_address).to eql address
      end

      it 'creates a new one time service' do
        fill_initial_service_form(conekta_card, one_time_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        service = Service.first
        expect(service).to be_present
        expect(service.service_type_id).to eql one_time_service.id
        expect(Schedule.available.count).to be 21
        expect(Schedule.booked.count).to be 4
      end

      it 'creates a new recurrent service' do
        fill_initial_service_form(conekta_card, recurrent_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        service = Service.first
        expect(service).to be_present

        recurrence = service.recurrence
        recurrence.aliada = recurrence.aliada
        user = service.user
        
        expect(recurrence.owner).to eql 'user'
        expect(recurrence.hour).to eql service.beginning_datetime.hour
        expect(recurrence.weekday).to eql service.beginning_datetime.weekday
        expect(recurrence.aliada).to eql aliada
        expect(recurrence.user).to eql user

        expect(recurrence.user).to eql user
        expect(recurrence.aliada).to eql aliada

        expect_to_have_a_complete_service(service)

        expect(service.service_type_id).to eql recurrent_service.id
        expect(Schedule.available.count).to be 5
        expect(Schedule.booked.count).to be 20
      end

      it 'logs in the new user' do
        fill_initial_service_form(conekta_card, one_time_service, starting_datetime + 1.day, extra_1, zone)

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
        fill_initial_service_form(conekta_card, one_time_service, starting_datetime, extra_1, zone)

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

  context 'with a logged in user' do
    let!(:aliada) { create(:aliada) }
    let!(:admin){ create(:admin) }
    let!(:user){ create(:user) }
    let!(:address){ create(:address, postal_code: postal_code, user: user) }
    let!(:conekta_card){ create(:conekta_card) }

    before do
      Timecop.freeze(starting_datetime)


      # We have hidden elements in our initial service creation assitant 
      # because we don't show all the steps at once
      @default_capybara_ignore_hidden_elements_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false

      visit initial_service_path

      login_as(user)
    end

    after do
      logout
      Capybara.ignore_hidden_elements = @default_capybara_ignore_hidden_elements_value
    end

    describe '#edit' do
      let(:user_service){ create(:service, 
                            aliada: aliada,
                            user: user,
                            estimated_hours: 3,
                            service_type: one_time_service) }
      let(:admin_service){ create(:service, 
                                  aliada: aliada,
                                  user: admin,
                                  service_type: one_time_service) }

      describe 'viewing permissions' do
        it 'lets the admin see the edit page of any service' do
          logout
          login_as(admin)

          edit_service_path = edit_service_users_path(user_id: user.id, service_id: user_service.id)

          visit edit_service_path
          
          expect(page.current_path).to eql edit_service_path
        end

        it 'doesnt let the user see the edit page ofr other users services' do
          edit_service_path = edit_service_users_path(user_id: admin.id, service_id: admin_service.id)

          visit edit_service_path
          
          expect(page.current_path).not_to eql edit_service_path
        end

        it 'let the user see the edit pages for its own services' do
          edit_service_path = edit_service_users_path(user_id: user.id, service_id: user_service.id)

          visit edit_service_path
          
          expect(page.current_path).to eql edit_service_path
        end
      end

      describe 'editing side effects' do

        context 'recurrent services' do
          before do
            The - 1 hour is needed because this hour is the one the aliada needs to get there from a previous service

            schedules_intervals = create_recurrent!(starting_datetime + 1.day - 1.hour, 
                                                    hours: 5,
                                                    periodicity: recurrent_service.periodicity ,
                                                    conditions: {zone: zone, aliada: aliada, service: user_service}, timezone: 'UTC')


            visit edit_service_users_path(user_id: user.id, service_id: user_service.id)
          end

          it 'doesnt let you downgrade from recurent to one time'

          it 'doesnt reschedule the service when hours doesnt change' do
            edit_service_path 

            service_previous_attributes = user_service.attributes

            fill_in 'service_special_instructions', with: 'Something different than previous value'
            fill_in 'service_garbage_instructions', with: 'Something different than previous value'

            click_button 'Confirmar visita'

            service_new_attributes = user_service.reload.attributes

            attributes_diff = HashDiff.diff(service_previous_attributes, service_new_attributes)

            expect(attributes_diff).to eql []

            expect(user_service).not_to have_received(:reschedule)
          end

          it 'lets the user edit the service hours updating the schedules' do
            # edit_service_path = edit_service_users_path(user_id: user.id, service_id: user.id)

            # visit edit_service_path

            # fill_hidden_input 'service_estimated_hours', with: 3
            # expect(service.estimated_hours).to eql 3
          end
        end
      end
    end

    describe '#new' do
      let(:new_service_path) { new_service_users_path(user) }

      before do
        expect(Service.count).to eql 0

        allow_any_instance_of(User).to receive(:aliadas).and_return([aliada])
        allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
        allow_any_instance_of(User).to receive(:postal_code_number).and_return(11800)
      end

      it 'let the user view the new service page' do
        visit new_service_path
        
        expect(page.current_path).to eql new_service_path
      end

      context 'one time service' do
        it 'lets the user create a new service' do
          visit new_service_path

          fill_new_service_form(one_time_service, starting_datetime + 1.day, extra_1, zone)

          click_button 'Confirmar visita'

          response = JSON.parse(page.body)
          expect(response['service_id']).to be_present

          service = Service.find(response['service_id'].to_i)

          expect_to_have_a_complete_service(service)
        end
      end

      context 'recurrent service' do
        it 'lets the user create a new service' do
          visit new_service_path

          fill_new_service_form(recurrent_service, starting_datetime + 1.day, extra_1, zone)

          click_button 'Confirmar visita'

          response = JSON.parse(page.body)
          expect(response['service_id']).to be_present

          service = Service.find(response['service_id'].to_i)
          aliada = service.aliada
          user = service.user
          recurrence = service.recurrence

          expect_to_have_a_complete_service(service)
          expect(recurrence.owner).to eql 'user'
          expect(recurrence.hour).to eql service.beginning_datetime.hour
          expect(recurrence.weekday).to eql service.beginning_datetime.weekday
          expect(recurrence.aliada).to eql aliada
          expect(recurrence.user).to eql user
        end
      end
    end
  end
end

