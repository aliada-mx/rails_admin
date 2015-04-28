# -*- encoding : utf-8 -*-
feature 'ServiceController' do
  include TestingSupport::SchedulesHelper

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') } # 7 am Mexico City
  let(:next_day_of_service) { Time.zone.parse('2015-01-08 13:00:00') }
  let!(:zone) { create(:zone) }
  let!(:aliada){ create(:aliada, zones: [zone]) }
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:other_recurrence) { create(:recurrence, user: other_user) }

  let!(:recurrent_service) { create(:service_type) }
  let!(:recurrence) { create(:recurrence,
                             user: user,
                             zone: zone,
                             estimated_hours: 3,
                             special_instructions: 'a plain instruction',
                             hours_after_service: 2,
                             aliada: aliada) }

  let!(:user_service){ create(:service, 
                        aliada: aliada,
                        user: user,
                        datetime: next_day_of_service,
                        estimated_hours: 4,
                        zone: zone,
                        service_type: recurrent_service,
                        recurrence: recurrence) }

  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              number: '11800') }
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:extra_2){ create(:extra, name: 'Limpieza de refri')}
  let!(:conekta_card_method){ create(:payment_method)}
  let!(:conekta_card){ create(:conekta_card) }

  before do
    Timecop.freeze(starting_datetime)

    @default_capybara_ignore_hidden_elements_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false

    create_recurrent!(next_day_of_service, hours: 6,
                                           periodicity: recurrence.periodicity ,
                                           conditions: {aliada: aliada,
                                                      recurrence: recurrence,
                                                      service: user_service,
                                                      status: 'booked'})


    allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)
    allow_any_instance_of(Recurrence).to receive(:timezone).and_return('UTC')

    login_as(user)

    visit edit_recurrence_users_path(user_id: user.id, recurrence_id: recurrence.id)
  end

  after do
    Capybara.ignore_hidden_elements = @default_capybara_ignore_hidden_elements_value
    Timecop.return
  end

  it 'enables all the recurrences schedules' do

  end

  describe '#edit' do
    it 'doesnt let other users edit the recurrences' do
      logout
      login_as(other_user)

      visit edit_recurrence_users_path(user_id: user.id, recurrence_id: recurrence.id)
      
      expect(current_path).to eql root_path
    end
    
    it 'lets an admin edit any user recurrence ' do
      logout
      login_as(admin)

      edit_user_recurrence_path = edit_recurrence_users_path(user_id: user.id, recurrence_id: recurrence.id)
      edit_recurrence_other_users_path = edit_recurrence_users_path(user_id: other_user.id, recurrence_id: other_recurrence.id)

      visit edit_user_recurrence_path 

      expect(current_path).to eql edit_user_recurrence_path 

      visit edit_recurrence_other_users_path 

      expect(current_path).to eql edit_recurrence_other_users_path 
    end

    it 'doesnt reschedule the service when datetime, estimated or hours change' do
      expect_any_instance_of(Recurrence).not_to receive(:reschedule!)

      fill_in 'recurrence_special_instructions', with: 'A very special instruction'
      fill_in 'recurrence_garbage_instructions', with: 'Garbage is not nice'

      click_button 'Guardar cambios'

      response = JSON.parse(page.body)
      expect(response['status']).to eql 'success'

      recurrence = Recurrence.find( response['recurrence_id'] )
      expect( recurrence.special_instructions ).to eql 'A very special instruction'
      expect( recurrence.garbage_instructions ).to eql 'Garbage is not nice'
    end

    it 'reschedules the service when the estimated hours change' do
      expect_any_instance_of(Recurrence).to receive(:reschedule!).and_call_original

      fill_hidden_input 'recurrence_estimated_hours', with: '5.0'
      fill_hidden_input 'recurrence_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_hidden_input 'recurrence_time', with: starting_datetime.strftime('%H:%M')

      click_button 'Guardar cambios'

      response = JSON.parse(page.body)
      expect(response['status']).to_not eql 'error'
      expect(response['recurrence_id']).to be_present

      recurrence = Recurrence.find(response['recurrence_id'])

      expect(recurrence.estimated_hours).to eql 5
      expect(recurrence.schedules.count).to eql 24
      expect(recurrence.schedules.padding.count).to eql 4
      expect(Schedule.available.count).to eql 0
    end

    it 'makes available schedules previously booked but not used anymore by the service' do
      expect_any_instance_of(Recurrence).to receive(:reschedule!).and_call_original

      fill_hidden_input 'recurrence_estimated_hours', with: '3.0'
      fill_hidden_input 'recurrence_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_hidden_input 'recurrence_time', with: starting_datetime.strftime('%H:%M')

      click_button 'Guardar cambios'

      response = JSON.parse(page.body)
      expect(response['status']).to_not eql 'error'
      expect(response['recurrence_id']).to be_present

      recurrence = Recurrence.find(response['recurrence_id'])

      expect(recurrence.estimated_hours).to eql 3
      expect(recurrence.schedules.in_or_after_datetime(next_day_of_service).count).to eql 20
      expect(recurrence.schedules.padding.count).to eql 8
      expect(Schedule.available.count).to eql 4
    end

    it 'changes the recurrence attributes' do
      expect_any_instance_of(Recurrence).to receive(:reschedule!).and_call_original

      fill_hidden_input 'recurrence_estimated_hours', with: '5.0'
      fill_hidden_input 'recurrence_date', with: next_day_of_service.strftime('%Y-%m-%d')
      fill_hidden_input 'recurrence_time', with: next_day_of_service.strftime('%H:%M')

      click_button 'Guardar cambios'

      response = JSON.parse(page.body)
      expect(response['status']).to_not eql 'error'
      expect(response['recurrence_id']).to be_present

      recurrence = Recurrence.find(response['recurrence_id'])

      expect(recurrence.total_hours).to eql 6
    end

    it 'cancels the previous services and creates new ones' do
      service_1 = create(:service, recurrence: recurrence, datetime: next_day_of_service)
      service_2 = create(:service, recurrence: recurrence, datetime: next_day_of_service)

      fill_hidden_input 'recurrence_estimated_hours', with: '4.0'
      fill_hidden_input 'recurrence_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_hidden_input 'recurrence_time', with: starting_datetime.strftime('%H:%M')

      click_button 'Guardar cambios'

      response = JSON.parse(page.body)
      expect(response['status']).to_not eql 'error'
      expect(response['recurrence_id']).to be_present
      
      recurrence = Recurrence.find(response['recurrence_id'])

      expect(service_1.reload).to be_canceled
      expect(service_2.reload).to be_canceled
      expect(recurrence.services.canceled).to include(service_1)
      expect(recurrence.services.canceled).to include(service_2)
      expect(recurrence.services.not_canceled.count).to be 4

      expect(Schedule.booked_or_padding.all? {|s| s.service_id.present? }).to be true
    end
    
  end

  describe '#cancel_all!' do

    it 'enables all the schedules' do
      click_button 'Cancelar recurrencia'

      expect( recurrence.schedules.all? { |s| s.available? } ).to be true
    end
  end
end
