# -*- encoding : utf-8 -*-
feature 'ServiceController' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::SchedulesHelper
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') } # 7 am Mexico City
  let(:next_day_of_service) { Time.zone.parse('2015-01-08 13:00:00') }
  let!(:zone) { create(:zone) }
  let!(:aliada) { create(:aliada, first_name: 'Aide', zones: [ zone ]) }
  let!(:recurrent_service) { create(:service_type) }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:one_time_from_recurrent) { create(:service_type, name: 'one-time-from-recurrent') }

  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              number: '11800') }
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:extra_2){ create(:extra, name: 'Limpieza de refri')}
  let!(:conekta_card_method){ create(:payment_method)}
  let!(:code_type){ create(:code_type) }
    
  before do
    allow_any_instance_of(Service).to receive(:timezone).and_return('UTC')
    allow(Service).to receive(:timezone).and_return('UTC')
  end

  describe '#initial' do
    before do
      Timecop.freeze(starting_datetime)

      create_recurrent!(starting_datetime + 1.day, hours: 5, periodicity: recurrent_service.periodicity ,conditions: {aliada: aliada})

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
        expect(CodeType.where(name: 'personal').count).to be 1

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
        expect(user.code).to be_present
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
        fill_initial_service_form(conekta_card_method, one_time_service, starting_datetime + 1.day, extra_1, zone)

        click_button 'Confirmar visita'

        response = JSON.parse(page.body)
        expect(response['status']).to_not eql 'error'
        expect(response['service_id']).to be_present

        service = Service.first
        expect(service).to be_present
        expect(service.service_type_id).to eql one_time_service.id
        expect(Schedule.available.count).to be 20
        expect(Schedule.booked.count).to be 3
        expect(Schedule.padding.count).to be 2
      end

      it 'creates a new recurrent service' do
        fill_initial_service_form(conekta_card_method, recurrent_service, starting_datetime + 1.day, extra_1, zone)

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
        expect(recurrence.hour).to eql service.datetime.hour
        expect(recurrence.weekday).to eql service.datetime.weekday
        expect(recurrence.aliada).to eql aliada
        expect(recurrence.user).to eql user

        expect(recurrence.user).to eql user
        expect(recurrence.aliada).to eql aliada

        expect_to_have_a_complete_service(service)

        expect(service.service_type_id).to eql recurrent_service.id
        expect(Schedule.available.count).to be 0
        expect(Schedule.booked.count).to be 15
        expect(Schedule.padding.count).to be 10
      end

      it 'logs in ithe new user' do
        fill_initial_service_form(conekta_card_method, one_time_service, starting_datetime + 1.day, extra_1, zone)

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
        fill_initial_service_form(conekta_card_method, one_time_service, starting_datetime + 1.day, extra_1, zone)

        fill_hidden_input 'conekta_temporary_token', with: 'tok_test_visa_4242'

        VCR.use_cassette('initial_service_conekta_card', match_requests_on: [:method, :conekta_charge]) do
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

        expect(payment.provider.class).to eql ConektaCard
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
    let!(:aliada) { create(:aliada, zones: [zone]) }
    let!(:other_aliada) { create(:aliada, zones: [zone]) }
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
      let!(:recurrence) { create(:recurrence, estimated_hours: 4) }

      let(:user_service){ create(:service, 
                            aliada: aliada,
                            user: user,
                            datetime: starting_datetime,
                            estimated_hours: 4,
                            hours_after_service: 0,
                            zone: zone,
                            service_type: one_time_service,
                            recurrence: recurrence) }
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

      describe '#cancel' do
        before :each do
          @future_service_interval = create_one_timer!( starting_datetime, hours: 3, conditions: { aliada: aliada, service: user_service, status: 'booked' } )
          @previous_service_interval = create_one_timer!( starting_datetime - 1.day, hours: 3, conditions: { aliada: aliada, service: user_service, status: 'booked' } )

          allow_any_instance_of(User).to receive(:aliadas).and_return([aliada])
          allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
          allow_any_instance_of(User).to receive(:postal_code_number).and_return(11800)

          edit_service_path = edit_service_users_path(user_id: user.id, service_id: user_service.id)

          visit edit_service_path
          
          expect(page.current_path).to eql edit_service_path
        end

        it 'enables the future schedules' do
          allow_any_instance_of(User).to receive(:charge!).and_return(Payment.new(status: 'paid'))

          expect(user_service.schedules.booked.sort).to eql ( @future_service_interval.schedules + @previous_service_interval.schedules ).sort
          expect((@future_service_interval.schedules + @previous_service_interval.schedules).all?{ |schedule| schedule.booked? }).to eql true

          click_button 'Cancelar servicio'
          
          expect(user_service.reload).to be_canceled
          expect(user_service.schedules.reload.booked.sort).to eql ( @previous_service_interval.schedules.sort )
          expect(@future_service_interval.schedules.all?{ |schedule| schedule.reload.available? }).to eql true
          expect(@previous_service_interval.schedules.all?{ |schedule| schedule.reload.booked? }).to eql true
        end

        it 'charges a fee if the cancelation happens > 24 hours before' do
          expect_any_instance_of(Service).to receive(:charge_cancelation_fee!).and_call_original
          expect_any_instance_of(ConektaCard).to receive(:charge!).and_return(Payment.new(status: 'paid'))
          expect(Payment.count).to be 0

          Timecop.travel(starting_datetime - 23.hours)

          click_button 'Cancelar servicio'

          expect(user_service.reload).to be_canceled
          expect(user_service.reload.cancelation_fee_charged).to be true
        end

        # TODO move to recurrence controller spec
        xit 'deactivates the recurrences and enables the schedules' do
          recurrence = create(:recurrence)
          service_1 = create(:service, recurrence: recurrence)
          service_2 = create(:service, recurrence: recurrence)

          user_service.recurrence = recurrence
          user_service.save!

          click_button 'Cancelar servicio'

          expect(user_service.reload).to be_canceled
          expect(user_service.recurrence.reload).to be_inactive
          expect(user_service.recurrence.services.all?(&:canceled?)).to be true
          expect(service_1.reload).to be_canceled
          expect(service_1.reload).to be_canceled
        end
      end

      describe '#update_existing' do

        context 'with one time service type' do

          before :each do
            create_one_timer!(next_day_of_service, hours: 6,  conditions: { aliada: aliada,
                                                                            service: user_service,
                                                                            status: 'booked' } )

            allow_any_instance_of(User).to receive(:aliadas).and_return([aliada])
            allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
            allow_any_instance_of(User).to receive(:postal_code_number).and_return(11800)

            edit_service_path = edit_service_users_path(user_id: user.id, service_id: user_service.id)

            visit edit_service_path
            
            expect(page.current_path).to eql edit_service_path
          end

          it 'reschedules a service when hours or date time change' do
            expect_any_instance_of(Service).to receive(:reschedule!).and_call_original

            fill_hidden_input 'service_estimated_hours', with: '5.0'
            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
          end

          it 'doesnt modify the recurrence when editing one timer' do
            expect(recurrence.estimated_hours).to eql 4
            expect(user_service.estimated_hours).to eql 4

            fill_hidden_input 'service_estimated_hours', with: '5.0'
            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
            expect(response['service_id']).to be_present

            service = Service.find(response['service_id'])

            expect(user_service).to eql service
            expect(service.estimated_hours).to eql 5
            expect(recurrence.estimated_hours).to eql 4
          end

          it 'enables the unused schedules' do
            expect(Schedule.booked.count).to eql 6

            fill_hidden_input 'service_estimated_hours', with: '3.0'
            fill_hidden_input 'service_date', with: next_day_of_service.strftime('%Y-%m-%d')
            fill_hidden_input 'service_time', with: next_day_of_service.strftime('%H:%M')

            click_button 'Guardar cambios'

            response = JSON.parse(page.body)
            expect(response['status']).to_not eql 'error'
            expect(response['service_id']).to be_present

            service = Service.find(response['service_id'])

            expect(service.schedules.in_or_after_datetime(next_day_of_service).count).to eql 5
            expect(service.schedules.padding.count).to eql 2
            expect(Schedule.available.count).to eql 1
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

        create_recurrent!(starting_datetime + 1.day,hours: 5,
                                                    periodicity: recurrent_service.periodicity ,
                                                    conditions: { aliada: aliada } )  
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
          expect(recurrence.hour).to eql service.datetime.hour
          expect(recurrence.weekday).to eql service.datetime.weekday
          expect(recurrence.aliada).to eql aliada
          expect(recurrence.user).to eql user
        end
      end
    end
  end
end

