describe 'ScheduleInterval' do
  let(:starting_datetime){ Time.zone.now.change({hour: 13})}
  let(:ending_datetime){ starting_datetime + 5.hour}

  describe '#build_from_range' do

    before :each do
      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
    end

    it 'should be valid with a valid schedules  intervals' do
      expect(@schedule_interval).to be_valid
    end

    it 'validates is not possible to create inverse schedules intervals' do
      schedule_interval = ScheduleInterval.build_from_range(ending_datetime, starting_datetime)

      expect(schedule_interval).to be_invalid
    end

    it 'validates all the datetimes exist' do
      @schedule_interval.schedules.first.datetime = nil

      expect{ @schedule_interval.valid? }.to raise_error
    end

    it 'has a correct number of schedules for each interval' do
      expect(@schedule_interval.size).to eql 5
    end

    it 'validates the datimes are continuous' do
      broken_schedules = @schedule_interval.schedules[1..2] + @schedule_interval.schedules[4..5]
      broken_schedule_interval = ScheduleInterval.new(broken_schedules )

      expect(broken_schedule_interval).to be_invalid
    end
  end

  describe '#-' do
    it 'returns the difference between two intervals' do
      difference = 1.day
      schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
      other_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + difference, ending_datetime + difference)

      (schedule_interval - other_schedule_interval) == difference
    end
  end

  describe '#include?' do
    before :each do
      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
    end

    it 'returns true if the interval includes the passed schedule' do
      schedule = Schedule.new(datetime: starting_datetime + 1.hour)

      expect(@schedule_interval.include? schedule).to be true
    end
  end
end
