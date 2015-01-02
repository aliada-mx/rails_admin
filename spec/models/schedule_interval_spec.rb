require 'test_helper'

describe 'ScheduleInterval' do
  let(:start_date){ Time.now.utc.change({hour: 7})}
  let(:end_date){ start_date + 3.hour}
  let(:aliada){ create(:aliada) }
  
  describe '#create' do
    it 'should be valid with a valid schedules  intervals' do
      schedule_interval = ScheduleInterval.create_from_range(start_date, end_date, aliada)
      
      expect(schedule_interval).to be_valid
    end

    it 'should not be possible to create inverse schedules intervals' do
      schedule_interval = ScheduleInterval.create_from_range(end_date, start_date, aliada)

      expect{ schedule_interval.valid? }.to raise_error
    end

    it 'should not be possible to create schedules intervals without datetimes or aliadas' do
      schedule_interval = ScheduleInterval.create_from_range(start_date, end_date, aliada)
      schedule_interval.schedules.first.datetime = nil

      expect{ schedule_interval.valid? }.to raise_error
    end
  end
end
