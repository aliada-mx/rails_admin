describe 'ScheduleChecker' do
  describe '#dates_available' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:other_aliada){ create(:aliada) }
    starting_datetime = Time.zone.now.change({hour: 7})
    ending_datetime = starting_datetime + 6.hour

    before do
      Timecop.freeze(starting_datetime)

      7.times do |i|
        create(:schedule, datetime: starting_datetime + i.hour, status: 'available', aliada: aliada, zone: zone)
      end
      7.times do |i|
        create(:schedule, datetime: starting_datetime + i.hour, status: 'available', aliada: other_aliada, zone: zone)
      end

      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours, conditions: {aliada_id: aliada.id})
      @before_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)
      @after_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + 7.hour, ending_datetime + 7.hour)

      @service = double(to_schedule_intervals: [@schedule_interval], 
                        to_schedule_interval: @schedule_interval,
                        zone: zone,
                        recurrent?: false)
      @checker = ScheduleChecker.new(@service)
    end

    after do
      Timecop.return
    end

    it 'finds an available datetime' do
      available_schedules = @checker.match_schedules

      expect(available_schedules).to be_present
    end

    it 'returns a list of schedule intervals with aliadas ids' do
      available_schedules = @checker.match_schedules

      expect(available_schedules.size).to be 2
      expect(available_schedules.has_key? aliada.id).to be true
      expect(available_schedules[aliada.id].first.beginning_of_interval).to eql starting_datetime
      expect(available_schedules[aliada.id].size).to be 1

      expect(available_schedules.has_key? other_aliada.id).to be true
      expect(available_schedules[other_aliada.id].first.beginning_of_interval).to eql starting_datetime
      expect(available_schedules[other_aliada.id].size).to be 1
    end

    it 'doesnt find an available datetime when the available schedules have holes in the continuity' do
      Schedule.where(datetime: starting_datetime + 1.hour).destroy_all
      available_schedules = @checker.match_schedules
      
      expect(available_schedules).to be_empty
    end

    it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
      service = double(to_schedule_intervals: [@before_availability_schedule_interval],
                       to_schedule_interval: @before_availability_schedule_interval,
                       zone: zone,
                       recurrent?: false)
      available_schedules = ScheduleChecker.new(service).match_schedules
      
      expect(available_schedules).to be_empty
    end
    
    it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
      service = double(to_schedule_intervals: [@after_availability_schedule_interval],
                       to_schedule_interval: @after_availability_schedule_interval,
                       zone: zone,
                       recurrent?: false)
      available_schedules = ScheduleChecker.new(service).match_schedules
      
      expect(available_schedules).to be_empty
    end
  end
end
