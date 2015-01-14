

describe 'ScheduleInterval' do
  let(:starting_datetime){ Time.now.utc.change({hour: 13})}
  let(:ending_datetime){ starting_datetime + 6.hour}

  describe '#create' do

    before :each do
      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
    end

    it 'should be valid with a valid schedules  intervals' do
      expect(@schedule_interval).to be_valid
    end

    it 'should not be possible to create inverse schedules intervals' do
      schedule_interval = ScheduleInterval.build_from_range(ending_datetime, starting_datetime)

      expect{ schedule_interval.valid? }.to raise_error
    end

    it 'should not be possible to create schedules intervals without datetimes or aliadas' do
      @schedule_interval.schedules.first.datetime = nil

      expect{ @schedule_interval.valid? }.to raise_error
    end

    it 'should have a correct number of schedules for each interval' do
      expect(@schedule_interval.hours_long).to eql 5
    end
  end
end
