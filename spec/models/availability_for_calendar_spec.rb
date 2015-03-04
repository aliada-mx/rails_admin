describe 'AvailabilityForCalendar' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  describe '#find' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:aliada_2){ create(:aliada) }
    let!(:aliada_3){ create(:aliada) }
    starting_datetime = Time.zone.now.change({hour: 7})
    ending_datetime = starting_datetime + 6.hour

    before do
      @user = double(banned_aliadas: [])
      @recurrence = double(periodicity: double(days: 7))
    end

    context 'for a one time service' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 5, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime + 5.hours, hours: 5, conditions: {aliada: aliada_2, zone: zone} )
        create_one_timer!(starting_datetime + 10.hours, hours: 5, conditions: {aliada: aliada_3, zone: zone} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @finder = AvailabilityForCalendar.new(5, zone)
      end

      after do
        Timecop.return
      end

      it 'finds an available datetime' do
        aliadas_availability = @finder.find

        expect(aliadas_availability).to be_present
      end

      it 'returns a list of schedule intervals' do
        aliadas_availability = @finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliadas_availability.size).to be 3
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada.id
        expect(aliada_1_availability.schedules_intervals.first.size).to be 5

        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 5.hour
        expect(aliada_2_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_2.id
        expect(aliada_2_availability.schedules_intervals.first.size).to be 5

        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 10.hour
        expect(aliada_3_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_3.id
        expect(aliada_3_availability.schedules_intervals.first.size).to be 5
      end

      it 'it doesnt find availability if there is a missing hour' do
        Schedule.where(datetime: starting_datetime).destroy_all
        finder = AvailabilityForCalendar.new(5, zone)
        aliadas_availability = finder.find

        expect(aliadas_availability.size).to be 2

        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 5.hours
        expect(aliada_2_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_2.id
        expect(aliada_2_availability.schedules_intervals.first.size).to be 5

        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 10.hours
        expect(aliada_3_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_3.id
        expect(aliada_3_availability.schedules_intervals.first.size).to be 5
      end

      it 'it finds availability when at least one aliada has it for a specific hour' do
        Schedule.where('aliada_id in (?)', [aliada_2, aliada_3]).destroy_all
        finder = AvailabilityForCalendar.new(5, zone)

        aliadas_availability = finder.find

        expect(aliadas_availability.size).to be 1
        expect(aliadas_availability.schedules_intervals[0].beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability.schedules_intervals[0].size).to be 5
        expect(aliadas_availability.schedules_intervals[0].schedules.first.aliada_id).to be aliada.id
      end

      it 'doesnt find an available datetime when are requested more hours than the available schedules' do
        aliadas_availability = AvailabilityForCalendar.new(8, zone).find
        
        expect(aliadas_availability).to be_empty
      end
    end

    context 'for a recurrent service ' do

      before do
        Timecop.freeze(starting_datetime)

        create_recurrent!(starting_datetime,           hours: 4, periodicity: 7, conditions: {aliada: aliada, zone: zone} )
        create_recurrent!(starting_datetime + 4.hours, hours: 3, periodicity: 7, conditions: {aliada: aliada_2, zone: zone} )

        @finder = AvailabilityForCalendar.new(3, zone, recurrent: true, periodicity: 7)
      end

      after do
        Timecop.return
      end

      it 'finds an aliada availability' do
        aliadas_availability = @finder.find

        expect(aliadas_availability.size).not_to eql 0
      end

      it 'returns a list of schedule intervals with aliadas ids' do
        aliadas_availability = @finder.find

        expect(aliadas_availability.size).to be 3
        expect(aliadas_availability.schedules_intervals.size).to be 15

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)

        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.size).to be 10
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.size).to be 5
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 4.hours + 7.days, aliada_id: aliada_2).destroy_all
        finder = AvailabilityForCalendar.new(3, zone, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 2

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end

      it 'doesnt find an available datetime when we more than there are available' do
        aliadas_availability = AvailabilityForCalendar.new(5, zone, recurrent: true, periodicity: 7).find
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find availability when the recurrence is too small(not enough schedules intervals)' do
        last_aliada_2_schedule = Schedule.where(aliada: aliada_2).order(:datetime).last
        last_aliada_2_schedule.book!

        aliadas_availability = AvailabilityForCalendar.new(3, zone, recurrent: true, periodicity: 7).find
        
        expect(aliadas_availability.size).to be 2

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end
    end

    context 'with a pre chosen aliada' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 3, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime, hours: 3, conditions: {aliada: aliada_2, zone: zone} )

        @finder = AvailabilityForCalendar.new(3, zone, aliada_id: aliada)
      end

      after do
        Timecop.return
      end
      it 'returns only the aliada´s availability' do
        aliadas_availability = @finder.find

        expect(aliadas_availability.size).to be 1

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end
    end
  end
end
