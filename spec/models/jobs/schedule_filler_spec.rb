# -*- encoding : utf-8 -*-
describe 'Schedule Filler' do
  # Preconditions:
  let(:starting_datetime){ Time.zone.parse('10 Apr 2015 00:00:00') }
  let(:recurrence_service_datetime) { Time.zone.parse('10 Apr 2015 13:00:00') }
  total_available_hours = 8
  total_service_hours = 3
  # aliada recurrence
  let(:zone){ create(:zone) }
  let(:aliada){ create(:aliada) }
  let(:user){ create(:user) }
  # client's recurrence, built with aliada's recurrence
  let!(:client_recurrence) { create(:recurrence,
                                    weekday: recurrence_service_datetime.weekday,
                                    hour: 7,
                                    special_instructions: 'some very special sinstructions',
                                    aliada: aliada,
                                    user: user,
                                    estimated_hours: 3,
                                    hours_after_service: 0) }
  let!(:service_type) { create(:service_type) }

  before do
    Timecop.freeze(starting_datetime)
    # Creating 1 hour aliada_working_hours
    (7..(7 + total_available_hours - 1)).each do |i|
      AliadaWorkingHour.create(weekday: recurrence_service_datetime.weekday, hour: i, aliada: aliada, total_hours: 1, periodicity: 7)
    end
  end

  after do
    Timecop.return
  end

  describe 'valid schedule filler in a specific day' do

    it 'creates schedules for aliada in a specific day' do
      # Exact number of total, booked and available schedules created
      specific_day = Time.zone.parse('03 Apr 2015 00:00:00')
      ScheduleFiller.fill_schedule_for_specific_day specific_day

      expect(Schedule.where("datetime < ?", Time.zone.now).count).to be total_available_hours
      expect(Schedule.available.where("datetime < ?", Time.zone.now).count).to be (total_available_hours - total_service_hours)
      expect(Schedule.booked.where("datetime < ?", Time.zone.now).count).to be total_service_hours
      expect(Schedule.booked.first.recurrence).to eql client_recurrence

      #Compensate for UTC 
      recurrence_in_the_past = specific_day.change(hour: client_recurrence.utc_hour(specific_day))

      expect(Schedule.booked.where("datetime < ?", Time.zone.now).first.datetime).to eql recurrence_in_the_past
      # Check the service date created for the client's recurrence in the future
      expect(Service.last.datetime).to eql recurrence_in_the_past

      # Check that it has been created using the first created service
      expect(Service.last.special_instructions).to eql client_recurrence.special_instructions
    end

  end

  describe 'valid filled schedules' do

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
      today_in_the_future = starting_datetime + Setting.time_horizon_days.days

      #Compensate for UTC 
      recurrence_in_the_future = today_in_the_future.change(hour: client_recurrence.utc_hour(today_in_the_future))

      expect(Schedule.booked.in_the_future.first.datetime).to eql recurrence_in_the_future
      # Check that it has been created using the recurrence attributes
      expect(Service.last.special_instructions).to eql client_recurrence.special_instructions
    end
 
  end

end
