require 'test_helper'

describe 'ScheduleInterval' do
  let(:start_date){ Time.now.utc.change({hour: 7})}
  let(:end_date){ start_date + 3.hour}
  let(:aliada){ create(:aliada) }
  
  describe '#create' do
    it 'should be valid with a valid schedules block' do
      schedule_interval = Schedule.create_schedule_interval(start_date, end_date, aliada)
      
      expect(schedule_interval).to be_valid
    end

    it 'should not be valid with an unordered schedules block' do
      schedule_interval = Schedule.create_schedule_interval(end_date, start_date, aliada)
      expect(schedule_interval).not_to be_valid
    end
    
    
  end
end
