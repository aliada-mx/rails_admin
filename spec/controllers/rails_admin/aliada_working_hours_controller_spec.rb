# -*- encoding : utf-8 -*-
feature 'AliadaWorkingHourController' do
  include TestingSupport::SchedulesHelper
  
  let(:admin){ create(:admin) }
  let(:starting_datetime){ Time.zone.parse('01 Apr 2015 00:00:00').in_time_zone("Mexico City") }
  total_available_hours = 8
  let(:zone){ create(:zone) }
  let!(:aliada){ create(:aliada, zones:[zone]) }

  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  context '#aliada_working_hour changes through admin' do

    before do
      init_hour = 7 
      # Filling initial monday aliada_working_hours
      (7..(7 + total_available_hours - 1)).each do |i|
        AliadaWorkingHour.create(weekday: 'monday', hour: i, aliada: aliada, total_hours: 1, owner: 'aliada', periodicity: 7)
      end
      login_as(admin)
    end

    it 'should update working hours' do
      expect(aliada.aliada_working_hours).not_to be_empty 
      expect(aliada.aliada_working_hours.first.weekday).to eql "monday"
      expect(aliada.aliada_working_hours.first.hour).to eql 7 
      expect(aliada.aliada_working_hours.first.status).to eql "active"
      #Inactivate sunday and create monday recurrences
      monday_recurrences = [ {hour: 7, weekday: 'monday'}]
      thursday_recurrences = [ {hour: 7, weekday: 'thursday'}]
      
      with_rack_test_driver do
        page.driver.submit :post, "/aliadadmin/aliada/#{aliada.id}/create_aliada_working_hours", { recurrences: {activated_recurrences: [], disabled_recurrences: monday_recurrences, new_recurrences: thursday_recurrences } }
      end

      response = JSON.parse(page.body)
      expect(response['status']).to eql 'success' 

      #Validate inactive sunday recurrences
      expect(aliada.aliada_working_hours.first.weekday).to eql "monday"
      expect(aliada.aliada_working_hours.first.hour).to eql 7 
      expect(aliada.aliada_working_hours.first.status).to eql "inactive"
      #Validate new active monday recurrences
      new_thursday_recurrence = AliadaWorkingHour.find_by(hour: 7, weekday: 'thursday', aliada_id: aliada.id)
      expect(new_thursday_recurrence.weekday).to eql 'thursday'
      expect(new_thursday_recurrence.hour).to eql 7
      expect(new_thursday_recurrence.status).to eql 'active'
      #Reactivate sunday recurrences
      with_rack_test_driver do
        page.driver.submit :post, "/aliadadmin/aliada/#{aliada.id}/create_aliada_working_hours", { recurrences: {activated_recurrences: monday_recurrences, disabled_recurrences: [], new_recurrences: [] } }
      end
      
      response = JSON.parse(page.body)
      expect(response['status']).to eql 'success' 

      active_monday_recurrence = AliadaWorkingHour.find_by(hour: 7, weekday: 'monday', aliada_id: aliada.id)
      expect(active_monday_recurrence.weekday).to eql 'monday'
      expect(active_monday_recurrence.hour).to eql 7 
      expect(active_monday_recurrence.status).to eql 'active'
      #Unchanged monday recurrences
      new_thursday_recurrence = AliadaWorkingHour.find_by(hour: 7, weekday: 'thursday', aliada_id: aliada.id)
      expect(new_thursday_recurrence.weekday).to eql 'thursday'
      expect(new_thursday_recurrence.hour).to eql 7
      expect(new_thursday_recurrence.status).to eql 'active'

    end

  end

end
