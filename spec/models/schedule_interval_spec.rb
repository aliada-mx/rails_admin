require 'test_helper'

describe 'ScheduleInterval' do
  let(:start_date){ Time.now }
  let(:end_date){ start_date + 1.day}
  let(:aliada){ create(:aliada) }
  
  describe '#create' do
    it 'should be valid with a valid dates range' do
      schedule_interval = Schedule.create_schedule_interval(start_date, end_date, aliada)
      
      expect(schedule_interval).to be_valid
    end

    it 'should not be valid with an in valid dates range' do
      schedule_interval = Schedule.create_schedule_interval(end_date, start_date, aliada)
      
      expect(schedule_interval).not_to be_valid
    end
  end
end
