feature 'AliadaWorkingHourController' do
  include TestingSupport::SchedulesHelper
  
  let(:admin){ create(:admin) }
  let(:starting_datetime){ Time.zone.parse('01 Jan 2015 00:00:00') }
  let(:recurrence_service_datetime) { Time.zone.parse('04 Jan 2015 13:00:00') }
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
      init_hour = recurrence_service_datetime.hour
      (init_hour..(init_hour + total_available_hours - 1)).each do |i|
        AliadaWorkingHour.create(weekday: recurrence_service_datetime.weekday, hour: i, aliada: aliada, total_hours: 1, owner: 'aliada', periodicity: 7)
      end
      login_as(admin)
    end

    it 'should update working hours' do
      expect(aliada.aliada_working_hours).not_to be_empty 
      expect(aliada.aliada_working_hours.first.weekday).to eql "sunday"
      expect(aliada.aliada_working_hours.first.hour).to eql 13
      expect(aliada.aliada_working_hours.first.status).to eql "active"
      #Inactivate sunday and create monday recurrences
      sunday_recurrences = [ {hour: 13, weekday: 'sunday'}]
      monday_recurrences = [ {hour: 9, weekday: 'monday'}]
      
      with_rack_test_driver do
        page.driver.submit :post, "/aliadadmin/aliada/#{aliada.id}/create_aliada_working_hours", { recurrences: {activated_recurrences: [], disabled_recurrences: sunday_recurrences, new_recurrences: monday_recurrences } }
      end

      #Validate inactive sunday recurrences
      expect(aliada.aliada_working_hours.first.weekday).to eql "sunday"
      expect(aliada.aliada_working_hours.first.hour).to eql 13
      expect(aliada.aliada_working_hours.first.status).to eql "inactive"
      #Validate new active monday recurrences
      new_monday_recurrence = AliadaWorkingHour.find_by(hour: 9, weekday: 'monday', aliada_id: aliada.id)
      expect(new_monday_recurrence.weekday).to eql 'monday'
      expect(new_monday_recurrence.hour).to eql 9
      expect(new_monday_recurrence.status).to eql 'active'
      #Reactivate sunday recurrences
      with_rack_test_driver do
        page.driver.submit :post, "/aliadadmin/aliada/#{aliada.id}/create_aliada_working_hours", { recurrences: {activated_recurrences: sunday_recurrences, disabled_recurrences: [], new_recurrences: [] } }
      end

      active_sunday_recurrence = AliadaWorkingHour.find_by(hour: 13, weekday: 'sunday', aliada_id: aliada.id)
      expect(active_sunday_recurrence.weekday).to eql 'sunday'
      expect(active_sunday_recurrence.hour).to eql 13
      expect(active_sunday_recurrence.status).to eql 'active'
      #Unchanged monday recurrences
      new_monday_recurrence = AliadaWorkingHour.find_by(hour: 9, weekday: 'monday', aliada_id: aliada.id)
      expect(new_monday_recurrence.weekday).to eql 'monday'
      expect(new_monday_recurrence.hour).to eql 9
      expect(new_monday_recurrence.status).to eql 'active'

    end

  end

end
