# -*- coding: utf-8 -*-
feature 'ServiceController' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::SchedulesHelper
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') } # 7 am Mexico City
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
    allow(Service).to receive(:timezone).and_return('UTC')
  end

  describe '#initial' do
    before do
      Timecop.freeze(starting_datetime)

      create_recurrent!(starting_datetime + 1.day, hours: 5, periodicity: recurrent_service.periodicity ,conditions: {zone: zone, aliada: aliada})

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

        allow_any_instance_of(User).to receive(:create_payment_provider!).and_return(nil)
        allow_any_instance_of(User).to receive(:ensure_first_payment!).and_return(nil)

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

        expect(service_aliada).to be_present
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

        response = JSON.parse(page.body)
        expect(response['status']).to_not eql 'error'
        expect(response['service_id']).to be_present

        service = Service.first
        expect(service).to be_present
        expect(service.service_type_id).to eql one_time_service.id
        expect(Schedule.available.count).to be 21
        expect(Schedule.booked.count).to be 4
      end

      it 'creates a new recurrent service' do
        fill_initial_service_form(conekta_card, recurrent_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        response = JSON.parse(page.body)
        expect(response['status']).to_not eql 'error'
        expect(response['service_id']).to be_present

        service = Service.first
        expect(service).to be_present

        recurrence = service.recurrence
        recurrence.aliada = recurrence.aliada
        user = service.user
        
        expect(service.aliada).to be_present
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

        response = JSON.parse(page.body)
        expect(response['status']).to_not eql 'error'
        expect(response['service_id']).to be_present
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

      it 'creates a pre-acthorization payment when choosing conekta' do
        fill_initial_service_form(conekta_card, one_time_service, starting_datetime + 1.day, extra_1, zone)

        fill_hidden_input 'conekta_temporary_token', with: 'tok_test_visa_4242'

        VCR.use_cassette('initial_service_conekta_card', match_requests_on: [:method, :conekta_preauthorization]) do
          click_button 'Confirmar visita'
        end

        response = JSON.parse(page.body)
        expect(response['status']).to_not eql 'error'
        expect(response['service_id']).to be_present
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
                            datetime: starting_datetime,
                            estimated_hours: 4,
                            zone: zone,
                            service_type: recurrent_service) }
      let(:admin_service){ create(:service, 
                                  aliada: aliada,
                                  user: admin,
                                  service_type: one_time_service) }

      before do
        user_service.ensure_updated_recurrence!
      end

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
        let(:next_day_of_service) { Time.zone.parse('2015-01-08 13:00:00') }

        before do
          allow_any_instance_of(User).to receive(:aliadas).and_return([aliada])
          allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
          allow_any_instance_of(User).to receive(:postal_code_number).and_return(11800)
        end

        context 'recurrent services' do
          before do
            booked_intervals = create_recurrent!(starting_datetime, 
                                                 hours: 5,
                                                 periodicity: recurrent_service.periodicity ,
                                                 conditions: {zone: zone,
                                                              aliada: aliada,
                                                              service: user_service,
                                                              status: 'booked'})
            available_schedules_intervals = create_recurrent!(starting_datetime + 5.hours, 
                                                              hours: 1,
                                                              periodicity: recurrent_service.periodicity ,
                                                              conditions: {zone: zone, aliada: aliada})

            @booked_schedules_datetimes = intervals_array_to_schedules_datetimes(booked_intervals)
            @available_schedules_datetimes = intervals_array_to_schedules_datetimes(available_schedules_intervals)
            @schedules_datetimes_to_book = ( @available_schedules_datetimes - @booked_schedules_datetimes ).select { |s| s > next_day_of_service }

            visit edit_service_users_path(user_id: user.id, service_id: user_service.id)

            @default_capybara_ignore_hidden_elements_value = Capybara.ignore_hidden_elements
            Capybara.ignore_hidden_elements = false

            expect(user_service.schedules.count).to eql 25
            expect(Schedule.available.count).to eql 5
            expect(user_service.schedules.map(&:datetime).sort).to eql @booked_schedules_datetimes.sort
            expect(user_service.estimated_hours).to eql 4
          end

          after do
            Capybara.ignore_hidden_elements = @default_capybara_ignore_hidden_elements_value
          end

          it 'doesnt let you downgrade from recurent to one time' do

          end

          it 'doesnt reschedule the service when datetime, estimated or hours change' do
            expect_any_instance_of(Service).not_to receive(:reschedule!)

            fill_in 'service_special_instructions', with: 'Something different than previous value'
            fill_in 'service_garbage_instructions', with: 'Something different than previous value'

            click_button 'Guardar cambios'
          end

          it 'doesnt let you dowgrade to one time service from a recurrent' do
            expect(user_service).to be_recurrent

            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')
            choose "service_service_type_id_#{one_time_service.id}", disabled: true
            # Simulate somebody manipulating the form
            remove_disabled "service_service_type_id_#{one_time_service.id}"

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to eql 'error'
            expect(response['code']).to eql 'downgrade_impossible'
          end

          it 'reschedules the service when the estimated hours change' do
            expect_any_instance_of(Service).to receive(:reschedule!).and_call_original
            select_by_value(5.0, from:'service_estimated_hours')
            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
            expect(response['service_id']).to be_present

            service = Service.find(response['service_id'])

            expect(service.estimated_hours).to eql 5
            expect(service.schedules.count).to eql 29

            expect(@schedules_datetimes_to_book - service.schedules.map(&:datetime)).to be_empty 
          end

          it 'makes available schedules previously booked but not used anymore by the service' do
            expect_any_instance_of(Service).to receive(:reschedule!).and_call_original
            select_by_value(3.0, from: 'service_estimated_hours')
            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
            expect(response['service_id']).to be_present

            service = Service.find(response['service_id'])

            expect(service.estimated_hours).to eql 3
            expect(service.schedules.count).to eql 21 # enabled 4 schedules
            expect(Schedule.available.count).to eql 9
          end

          it 'changes the recurrence attributes' do
            expect_any_instance_of(Service).to receive(:reschedule!).and_call_original
            expect(user_service.recurrence.total_hours).to eql 5

            select_by_value(5.0, from: 'service_estimated_hours')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
            expect(response['service_id']).to be_present

            service = Service.find(response['service_id'])

            expect(service.recurrence.total_hours).to eql 6
          end
        end
      end

      describe '#cancel' do
        before do
          @future_service_interval = create_one_timer!( starting_datetime, hours: 3, conditions: { zone: zone, aliada: aliada, service: user_service, status: 'booked' } )
          @previous_service_interval = create_one_timer!( starting_datetime - 1.day, hours: 3, conditions: { zone: zone, aliada: aliada, service: user_service, status: 'booked' } )

          allow_any_instance_of(User).to receive(:aliadas).and_return([aliada])
          allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
          allow_any_instance_of(User).to receive(:postal_code_number).and_return(11800)

          edit_service_path = edit_service_users_path(user_id: user.id, service_id: user_service.id)

          visit edit_service_path
          
          expect(page.current_path).to eql edit_service_path
        end

        it 'enables the future schedules' do
          expect(user_service.schedules.booked.sort).to eql ( @future_service_interval.schedules + @previous_service_interval.schedules ).sort
          expect((@future_service_interval.schedules + @previous_service_interval.schedules).all?{ |schedule| schedule.booked? }).to eql true

          click_button 'Cancelar'
          
          expect(user_service.schedules.reload.booked.sort).to eql ( @previous_service_interval.schedules.sort )
          expect(@future_service_interval.schedules.all?{ |schedule| schedule.reload.available? }).to eql true
          expect(@previous_service_interval.schedules.all?{ |schedule| schedule.reload.booked? }).to eql true
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

        create_recurrent!(starting_datetime + 1.day, hours: 5,
                                                     periodicity: recurrent_service.periodicity ,
                                                     conditions: { zone: zone, aliada: aliada } )  
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
          expect(response['status']).to_not eql 'error'
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
          expect(response['status']).to_not eql 'error'
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

