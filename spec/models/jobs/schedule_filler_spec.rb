describe 'Schedule Filler' do
  include SchedulesHelper 

  # Preconditions:
  let(:starting_datetime){ Time.zone.parse('09 Apr 2015 00:00:00') }
  let(:recurrence_service_datetime) { Time.zone.parse('12 Apr 2015 13:00:00') }
  total_available_hours = 8
  total_service_hours = 3
  # aliada recurrence
  let(:zone){ create(:zone) }
  let(:aliada){ create(:aliada) }
  let(:user){ create(:user) }
  let!(:one_time_from_recurrent){ create(:service_type, name: 'one-time-from-recurrent') }
  
  # client's recurrence, built with aliada's recurrence
  let!(:client_recurrence) { create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: 7, aliada: aliada, user: user, total_hours: total_service_hours, owner: 'user') }

  # services scheduled for client's schedule
  let!(:first_service){ create(:service, aliada: aliada, user: user, recurrence: client_recurrence, datetime: recurrence_service_datetime + 1.hour , special_instructions: "first service") }
  let!(:other_service){ create(:service, aliada: aliada, user: user, recurrence: client_recurrence, datetime: recurrence_service_datetime + 7.day + 1.hour, special_instructions: "last service") }

  before do
    Timecop.freeze(starting_datetime)
    # Creating 1 hour aliada_working_hours
    (7..(7 + total_available_hours - 1)).each do |i|
      AliadaWorkingHour.create(weekday: recurrence_service_datetime.weekday, hour: i, aliada: aliada, total_hours: 1, owner: 'aliada', periodicity: 7)
    end
  end

  after do
    Timecop.return
  end

  context '#valid schedule filler in a specific day' do

    it 'creates schedules for aliada in a specific day' do
      # Exact number of total, booked and available schedules created
      specific_day = Time.zone.parse('05 Apr 2015 00:00:00')
      ScheduleFiller.fill_schedule_for_specific_day specific_day

      expect(Schedule.where("datetime < ?", Time.zone.now).count).to be total_available_hours
      expect(Schedule.available.where("datetime < ?", Time.zone.now).count).to be (total_available_hours - total_service_hours)
      expect(Schedule.booked.where("datetime < ?", Time.zone.now).count).to be total_service_hours

      #Compensate for UTC 
      recurrence_in_the_past = specific_day.change(hour: client_recurrence.utc_hour(specific_day))

      expect(Schedule.booked.where("datetime < ?", Time.zone.now).first.datetime).to eql recurrence_in_the_past
      # Check the service date created for the client's recurrence in the future
      expect(Service.last.datetime).not_to eql first_service.datetime
      expect(Service.last.datetime).to eql recurrence_in_the_past

      # Check that it has been created using the first created service
      expect(Service.last.special_instructions).to eql first_service.special_instructions

    end

  end

  context '#valid_filled_schedules' do

    before do
      first_service.update_attribute(:created_at, first_service.created_at - 1.day)
      # Empty schedules before the job
      expect(Schedule.in_the_future.count).to be 0
      ScheduleFiller.perform(false)
    end

    it 'creates schedules for aliada' do
      # Exact number of total, booked and available schedules created
      expect(Schedule.in_the_future.count).to be total_available_hours
      expect(Schedule.available.in_the_future.count).to be (total_available_hours - total_service_hours)
      expect(Schedule.booked.in_the_future.count).to be total_service_hours
      # Check the specific date of the future schedule
      today_in_the_future = starting_datetime + Setting.time_horizon_days.days + 1.day

      #Compensate for UTC 
      recurrence_in_the_future = today_in_the_future.change(hour: client_recurrence.utc_hour(today_in_the_future))

      expect(Schedule.booked.in_the_future.first.datetime).to eql recurrence_in_the_future
      # Check the service date created for the client's recurrence in the future
      expect(Service.last.datetime).not_to eql first_service.datetime
      # Check that it has been created using the first created service
      expect(Service.last.special_instructions).to eql first_service.special_instructions
    end
 
  end

  context '#invalid_filled_schedules' do

    it "shows error of client's recurrence without services in it" do
      other_aliada = create(:aliada)
      # client's recurrence, built without aliada's recurrence
      other_client_recurrence = create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: other_aliada, user: user, total_hours: total_service_hours)
      expect{ScheduleFiller.perform(false)}.to raise_error(RuntimeError)
    end
  
    it "shows error of client's recurrence without an aliada's recurrence" do
      other_aliada = create(:aliada)
      # client's recurrence, built without aliada's recurrence
      other_client_recurrence = create(:recurrence, weekday: recurrence_service_datetime.weekday, hour: recurrence_service_datetime.hour, aliada: other_aliada, user: user, total_hours: total_service_hours)
      service = create(:service, aliada: other_aliada, user: user, recurrence: other_client_recurrence, datetime: recurrence_service_datetime, special_instructions: "first service")
      expect{ScheduleFiller.perform(false)}.to raise_error(RuntimeError)
    end

  end
  
end