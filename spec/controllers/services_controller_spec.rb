feature 'ServiceController' do
  include TestingSupport::ServiceControllerHelper
  include TestingSupport::SchedulesHelper
  include TestingSupport::SharedExpectations::ConektaCardExpectations

  starting_datetime = Time.zone.now.change({hour: 13})
  let!(:aliada) { create(:aliada) }
  let!(:zone) { create(:zone) }
  let!(:recurrent_service) { create(:service_type) }
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              code: '11800') }
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:extra_2){ create(:extra, name: 'Limpieza de refri')}
  let!(:conekta_card){ create(:payment_method)}
    

  before do
    Timecop.freeze(starting_datetime - 1.hour)

    # The - 1 hour is needed because this hour is the one the aliada needs to get there from a previous service
    create_recurrent!(starting_datetime - 1.hour, hours: 5, periodicity: recurrent_service.periodicity ,conditions: {zone: zone, aliada: aliada})

    expect(Address.all.count).to be 0
    expect(Service.all.count).to be 0
    expect(Aliada.all.count).to be 1

  end

  after do
    Timecop.return
  end

  describe '#initial' do
    it 'redirects the logged in user to new service' do
      user = create(:user)

      login_as(user)
      with_rack_test_driver do
        page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
      end

      expect(current_path).to eql new_service_users_path(user)
    end

    context 'Skipping the payment logic' do
      before do
        expect(User.where('role != ?', 'aliada').count).to be 0
        expect(Schedule.available.count).to be 25

        User.any_instance.stub(:create_payment_provider!).and_return(nil)
        User.any_instance.stub(:ensure_first_payment!).and_return(nil)

        with_rack_test_driver do
          page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
        end

        expect(current_path).to eq initial_service_path
      end

      after do
        service = Service.first
        address = service.address
        user = service.user
        extras = service.extras
        service_aliada = service.aliada

        expect(service_aliada).to eql aliada
        expect(extras).to include extra_1

        expect(address.street).to eql 'Calle de las aliadas'
        expect(address.number).to eql 1
        expect(address.interior_number).to eql 2
        expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
        expect(address.colony).to eql 'Roma'
        expect(address.state).to eql 'DF'
        expect(address.city).to eql 'Benito Juarez'

        expect(service.zone_id).to eql zone.id
        expect(service.billable_hours).to eql 3
        expect(service.bathrooms).to eql 1
        expect(service.bedrooms).to eql 1
        expect(service.special_instructions).to eql 'nada'

        expect(user.first_name).to eql 'Guillermo'
        expect(user.last_name).to eql 'Siliceo'
        expect(user.email).to eql 'guillermo.siliceo@gmail.com'
        expect(user.phone).to eql '5585519954'

      end

      it 'creates a new one time service' do
        fill_service_form(conekta_card, one_time_service, starting_datetime, extra_1)

        click_button 'Confirmar servicio'

        service = Service.first

        expect(service.service_type_id).to eql one_time_service.id
        expect(Schedule.available.count).to be 20
        expect(Schedule.booked.count).to be 5
      end

      it 'creates a new recurrent service' do
        fill_service_form(conekta_card, recurrent_service, starting_datetime, extra_1)

        click_button 'Confirmar servicio'

        service = Service.first
        user = service.user
        recurrence = service.recurrence
        recurrence_aliada = recurrence.aliada

        expect(recurrence_aliada).to eql aliada
        expect(recurrence.user).to eql user
        expect(recurrence.owner).to eql 'user'
        expect(recurrence.hour).to eql service.beginning_datetime.hour
        expect(recurrence.weekday).to eql service.beginning_datetime.weekday

        expect(service.service_type_id).to eql recurrent_service.id
        expect(Schedule.available.count).to be 0
        expect(Schedule.booked.count).to be 25
      end
    end

    context 'with real payment method' do
      before do
        expect(User.count).to be 0
        expect(Payment.count).to be 0
        expect(ConektaCard.count).to be 0
        expect(PaymentProviderChoice.count).to be 0

        with_rack_test_driver do
          page.driver.submit :post, initial_service_path, {postal_code_id: postal_code.id}
        end
      end

      it 'creates a pre-authorization payment when choosing conekta' do
        fill_service_form(conekta_card, one_time_service, starting_datetime, extra_1)

        fill_hidden_input 'conekta_temporary_token', with: 'tok_test_visa_4242'

        VCR.use_cassette('initial_service_conekta_card', match_requests_on: [:method, :conekta_preauthorization]) do
          click_button 'Confirmar servicio'
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
end
