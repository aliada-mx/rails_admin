describe 'ScheduleChecker' do
  describe '#dates_available' do
    let!(:aliada){ create(:aliada) }
    let!(:other_aliada){ create(:aliada) }
    starting_datetime = Time.now.utc.change({hour: 7})
    ending_datetime = starting_datetime + 6.hour

    before do
      30.times do |i|
        create(:schedule, datetime: starting_datetime + i.hour, status: 'available', aliada: aliada)
      end
      30.times do |i|
        create(:schedule, datetime: starting_datetime + i.hour, status: 'available', aliada: other_aliada)
      end

      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)
      @available_schedules = Schedule.available.ordered_by_user_datetime
    end

    it 'finds an available datetime' do
      expect(ScheduleChecker.check_datetimes(@available_schedules, @schedule_interval)).to be_present
    end

    it 'returns a list of schedule intervals with aliadas ids' do
      available_schedules = ScheduleChecker.check_datetimes(@available_schedules, @schedule_interval)

      expect(available_schedules.size).to be 2
      expect(available_schedules.has_key? aliada.id).to be true
      expect(available_schedules[aliada.id].first.beginning_of_interval).to eql starting_datetime
      expect(available_schedules[aliada.id].size).to be 1

      expect(available_schedules.has_key? other_aliada.id).to be true
      expect(available_schedules[other_aliada.id].first.beginning_of_interval).to eql starting_datetime
      expect(available_schedules[other_aliada.id].size).to be 1
    end

    it 'doesnt find an available datetime when the available schedules have holes in the continuity' do
      @available_schedules.delete(Schedule.where(datetime: starting_datetime + 1.hour))
      
      expect(ScheduleChecker.check_datetimes(@available_schedules, @schedule_interval)).to be_empty
    end

    it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
      @unavailable_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)
      
      expect(ScheduleChecker.check_datetimes(@available_schedules, @unavailable_schedule_interval)).to be_empty
    end
    
    it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
      @unavailable_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + 7.hour, ending_datetime + 7.hour)
      
      expect(ScheduleChecker.check_datetimes(@available_schedules, @unavailable_schedule_interval)).to be_empty
    end
  end
end
