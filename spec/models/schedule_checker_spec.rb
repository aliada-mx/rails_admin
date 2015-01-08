describe 'ScheduleChecker' do
  let!(:starting_datetime){ Time.now.utc.change({hour: 13})}
  let!(:ending_datetime){ starting_datetime + 6.hour}

  describe '#unique_per_aliada' do
    include_context 'schedules and schedules intervals' 

    it 'returns a correct number of aliadas groups' do
      unique_per_alida = ScheduleChecker.unique_per_aliada(@six_available_schedules, @two_hours_schedule_interval )

      expect(unique_per_alida.size).to be 2
    end

    it 'returns a correct number of aliadas schedules intervals' do
      unique_per_alida = ScheduleChecker.unique_per_aliada(@six_available_schedules, @two_hours_schedule_interval )

      expect(unique_per_alida.first.size).to be 2
    end
  end

  describe '#fits_in_schedules' do
    include_context 'schedules and schedules intervals' 

    it 'fits the schedule interval' do
      expect(ScheduleChecker.fits_in_schedules(@six_available_schedules, @two_hours_schedule_interval)).to be_present
    end

    it 'doesnt fit the schedule interval' do
      expect(ScheduleChecker.fits_in_schedules(@six_available_schedules, @eight_hours_schedule_interval)).to be_falsy
    end

    it 'returns a list of schedule intervals' do
      available_schedules = ScheduleChecker.fits_in_schedules(@six_available_schedules, @two_hours_schedule_interval)
      expect(available_schedules.size).to be 2
    end
  end
end
