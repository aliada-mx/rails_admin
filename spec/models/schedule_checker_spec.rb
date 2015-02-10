describe 'ScheduleChecker' do
  include TestingSupport::SchedulesHelper

  describe '#dates_available' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:aliada_2){ create(:aliada) }
    let!(:aliada_3){ create(:aliada) }
    starting_datetime = Time.zone.now.change({hour: 7})
    ending_datetime = starting_datetime + 6.hour

    before do
      @user = double(banned_aliadas: [])
      @recurrence = double(periodicity: double(days: 7.days))
    end

    context 'for a one time service' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada_2, zone: zone} )
        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada_3, zone: zone} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @service = double(to_schedule_intervals: [@schedule_interval], 
                          to_schedule_interval: @schedule_interval,
                          user: @user,
                          recurrence: @recurrence,
                          zone: zone,
                          one_timer?: true,
                          recurrent?: false)
        @checker = ScheduleChecker.new(@service)
      end

      after do
        Timecop.return
      end

      it 'finds an available datetime' do
        aliadas_availability = @checker.match_schedules

        expect(aliadas_availability).to be_present
      end

      it 'returns a list of schedule intervals with aliadas ids' do
        aliadas_availability = @checker.match_schedules

        expect(aliadas_availability.size).to be 3
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 1

        expect(aliadas_availability[aliada_2.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_2.id].size).to be 1

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 1
      end

      it 'doesnt find an available datetime when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 1.hour).destroy_all
        aliadas_availability = @checker.match_schedules
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)
        service = double(to_schedule_intervals: [before_availability_schedule_interval],
                         to_schedule_interval: before_availability_schedule_interval,
                         recurrence: @recurrence,
                         days_count_to_end_of_recurrency: 4,
                         user: @user,
                         zone: zone,
                         one_timer?: true,
                         recurrent?: false)
        aliadas_availability = ScheduleChecker.new(service).match_schedules
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
        after_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + 7.hour, ending_datetime + 7.hour)
        service = double(to_schedule_intervals: [after_availability_schedule_interval],
                         to_schedule_interval: after_availability_schedule_interval,
                         recurrence: @recurrence,
                         days_count_to_end_of_recurrency: 4,
                         user: @user,
                         zone: zone,
                         one_timer?: true,
                         recurrent?: false)
        aliadas_availability = ScheduleChecker.find_aliadas_availability(service)
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find a availability for banned aliadas' do
        user = double(banned_aliadas: [aliada_2])

        service = double(to_schedule_intervals: [@schedule_interval], 
                         to_schedule_interval: @schedule_interval,
                         user: user,
                         recurrence: @recurrence,
                         zone: zone,
                         one_timer?: true,
                         recurrent?: false)
        
        aliadas_availability = ScheduleChecker.find_aliadas_availability(service)

        expect(aliadas_availability.size).to be 2

        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 1

        expect(aliadas_availability[aliada_2.id].size).to be 0

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 1
      end
    end

    context 'for a recurrent service ' do

      before do
        Timecop.freeze(starting_datetime)

        create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada, zone: zone} )
        create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_2, zone: zone} )
        create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_3, zone: zone} )

        schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours, conditions: {aliada_id: aliada.id})

        service = double(to_schedule_intervals: [schedule_interval], 
                         to_schedule_interval: schedule_interval,
                         user: @user,
                         recurrence: @recurrence,
                         days_count_to_end_of_recurrency: 4,
                         zone: zone,
                         one_timer?: false,
                         recurrent?: true)
        @checker = ScheduleChecker.new(service)
      end

      after do
        Timecop.return
      end

      it 'finds an aliada availability' do
        aliadas_availability = @checker.match_schedules

        expect(aliadas_availability.size).not_to eql 0
      end

      it 'returns a list of schedule intervals with aliadas ids' do
        aliadas_availability = @checker.match_schedules

        expect(aliadas_availability.size).to be 3
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 5

        expect(aliadas_availability[aliada_2.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_2.id].size).to be 5

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 5
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 7.days, aliada_id: aliada_2).destroy_all
        aliadas_availability = @checker.match_schedules
        
        expect(aliadas_availability.size).to be 2
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 5

        expect(aliadas_availability[aliada_2.id].size).to be 0

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 5
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)

        service = double(to_schedule_intervals: [before_availability_schedule_interval],
                         to_schedule_interval: before_availability_schedule_interval,
                         user: @user,
                         recurrence: @recurrence,
                         days_count_to_end_of_recurrency: 5,
                         one_timer?: true,
                         zone: zone,
                         recurrent?: false)
        aliadas_availability = ScheduleChecker.new(service).match_schedules
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
        after_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + 7.hour, ending_datetime + 7.hour)
        service = double(to_schedule_intervals: [after_availability_schedule_interval],
                         to_schedule_interval: after_availability_schedule_interval,
                         user: @user,
                         recurrence: @recurrence,
                         days_count_to_end_of_recurrency: 5,
                         zone: zone,
                         one_timer?: true,
                         recurrent?: false)
        aliadas_availability = ScheduleChecker.new(service).match_schedules
        
        expect(aliadas_availability).to be_empty
      end
    end
  end
end
