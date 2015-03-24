describe 'Schedule Filler' do

  # Preconditions:
  let(:starting_datetime){ Time.zone.parse('01 Jan 2015 00:00:00') }
  let(:recurrence_service_datetime) { Time.zone.parse('04 Jan 2015 13:00:00') }
  total_available_hours = 8
  total_service_hours = 3
  # aliada recurrence
  let(:zone){ create(:zone) }
  let(:aliada){ create(:aliada) }
  let(:user){ create(:user) }
  # TODO: update to many 1 hour recurrences
  let!(:aliada_recurrence) { create(:aliada_working_hour, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: aliada, total_hours: total_available_hours, owner: 'aliada') }
  
  # client's recurrence, built with aliada's recurrence
  let!(:client_recurrence) { create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: aliada, user: user, total_hours: total_service_hours, owner: 'user') }

  # services scheduled for client's schedule
  let!(:first_service){ create(:service, aliada: aliada, user: user, recurrence: client_recurrence, datetime: recurrence_service_datetime, special_instructions: "first service") }
  let!(:other_service){ create(:service, aliada: aliada, user: user, recurrence: client_recurrence, datetime: recurrence_service_datetime + 7.day, special_instructions: "last service") }

  before do
    first_service.update_attribute(:special_instructions, "modified service")
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  context '#valid_filled_schedules' do

    before do
      # Empty schedules before the job
      expect(Schedule.in_the_future.count).to be 0
      ScheduleFiller.perform
    end

    it 'creates schedules for aliada' do
      # Exact number of total, booked and available schedules created
      expect(Schedule.in_the_future.count).to be total_available_hours
      expect(Schedule.available.in_the_future.count).to be (total_available_hours - total_service_hours)
      expect(Schedule.booked.in_the_future.count).to be total_service_hours
      # Check the specific date of the future schedule
      expect(Schedule.booked.in_the_future.first.datetime).to eql (starting_datetime + Setting.time_horizon_days.day + recurrence_service_datetime.hour.hour + 1.day) 
      # Check the service date created for the client's recurrence in the future
      expect(Service.last.datetime).not_to be first_service.datetime
      # Check that it has been created using the mst recent created service
      expect(Service.last.special_instructions).to eql first_service.special_instructions
    end
 
  end

  context '#invalid_filled_schedules' do

    it "shows error of client's recurrence without services in it" do
      other_aliada = create(:aliada)
      # client's recurrence, built without aliada's recurrence
      other_client_recurrence = create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: other_aliada, user: user, total_hours: total_service_hours)
      expect{ScheduleFiller.perform}.to raise_error(RuntimeError)
    end
  
    it "shows error of client's recurrence without an aliada's recurrence" do
      other_aliada = create(:aliada)
      # client's recurrence, built without aliada's recurrence
      other_client_recurrence = create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: other_aliada, user: user, total_hours: total_service_hours)
      service = create(:service, aliada: other_aliada, user: user, recurrence: other_client_recurrence, datetime: recurrence_service_datetime, special_instructions: "first service")
      expect{ScheduleFiller.perform}.to raise_error(RuntimeError)
    end

  end
  
end
