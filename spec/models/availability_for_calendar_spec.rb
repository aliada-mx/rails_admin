describe 'AvailabilityForCalendar' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  describe '#find' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:aliada_2){ create(:aliada) }
    let!(:aliada_3){ create(:aliada) }
    starting_datetime = Time.zone.parse('01 Jan 2015 13:00:00')

    before do
      @user = double(banned_aliadas: [])
      @recurrence = double(periodicity: double(days: 7))
    end

    context 'for a one time service' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime + 4.hours, hours: 4, conditions: {aliada: aliada_2, zone: zone} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @finder = AvailabilityForCalendar.new(3, zone, starting_datetime)
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

        expect(aliadas_availability.size).to be 2
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 3.hours
        expect(aliada_1_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada.id
        expect(aliada_1_availability.schedules_intervals.first.size).to be 4

        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 7.hours
        expect(aliada_2_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_2.id
        expect(aliada_2_availability.schedules_intervals.first.size).to be 4
      end

      it 'it doesnt find availability if there is a missing hour' do
        Schedule.where(datetime: starting_datetime + 1.hour).destroy_all
        finder = AvailabilityForCalendar.new(3, zone, starting_datetime)
        aliadas_availability = finder.find

        expect(aliadas_availability.size).to be 1

        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hours
        expect(aliada_2_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada_2.id
        expect(aliada_2_availability.schedules_intervals.first.size).to be 4
      end

      it 'it finds availability when at least one aliada has it for a specific hour' do
        Schedule.where(aliada_id: [aliada_2.id]).destroy_all
        finder = AvailabilityForCalendar.new(3, zone, starting_datetime)

        aliadas_availability = finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)

        expect(aliadas_availability.size).to be 1
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 3.hours
        expect(aliada_1_availability.schedules_intervals.first.schedules.first.aliada_id).to be aliada.id
        expect(aliada_1_availability.schedules_intervals.first.size).to be 4
      end

      it 'doesnt find an available datetime when are requested more hours than the available schedules' do
        aliadas_availability = AvailabilityForCalendar.new(8, zone, starting_datetime).find
        
        expect(aliadas_availability).to be_empty
      end

      it 'adds the service future schedules to the avalability' do
        aliadas_availability = AvailabilityForCalendar.new(8, zone, starting_datetime).find
      end
    end

    context 'for a recurrent service ' do

      before do
        Timecop.freeze(starting_datetime)

        create_recurrent!(starting_datetime,           hours: 6, periodicity: 7, conditions: {aliada: aliada, zone: zone} )
        create_recurrent!(starting_datetime + 4.hours, hours: 5, periodicity: 7, conditions: {aliada: aliada_2, zone: zone} )

        @finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: true, periodicity: 7)
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

        expect(aliadas_availability.size).to be 5
        expect(aliadas_availability.schedules_intervals.size).to be 25

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)

        expect(aliada_1_availability.schedules_intervals.size).to be 15

        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.size).to be 10
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 4.hours + 7.days, aliada_id: aliada_2).destroy_all
        finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 3

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end

      it 'doesnt find an available datetime when we want more than there are available' do
        finder = AvailabilityForCalendar.new(7, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find availability when the recurrence is too small(not enough schedules intervals)' do
        Schedule.where(aliada: aliada_2).order(:datetime).last.book!
        Schedule.where(aliada: aliada_2).order(:datetime).first.book!

        last_aliada_schedule = Schedule.where(aliada: aliada).order(:datetime).last
        last_aliada_schedule.book!

        finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 2

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end

      it 'finds the summed availability of all aliadas even if they have the same availabilites' do
        create_recurrent!(starting_datetime + 4.hours, hours: 5, periodicity: 7, conditions: {aliada: aliada_3, zone: zone} )

        aliadas_availability = AvailabilityForCalendar.new(4, zone, starting_datetime, recurrent: true, periodicity: 7).find

        expect(aliadas_availability.size).to be 4
        expect(aliadas_availability.schedules_intervals.size).to be 20

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.size).to be 10
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.size).to be 5

        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_3_availability.schedules_intervals.size).to be 5

        expect(aliada_3_availability.schedules.map(&:datetime).sort).to eql aliada_2_availability.schedules.map(&:datetime).sort
      end
    end

    context 'with a pre chosen aliada' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada_2, zone: zone} )

        @finder = AvailabilityForCalendar.new(3, zone, starting_datetime, aliada_id: aliada)
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

    context 'with a passed service' do
      let!(:service){ create(:service) }
      let!(:user){ create(:user) }

      before do
        Timecop.freeze(starting_datetime)
        booked_intervals = create_recurrent!(starting_datetime, hours: 4, periodicity: 7, conditions: {aliada: aliada, zone: zone, service: service, status: 'booked'} )

        available_intervals = create_recurrent!(starting_datetime + 1.day, hours: 4, periodicity: 7, conditions: {aliada: aliada, zone: zone, status: 'available'} )
        @available_schedules = available_intervals.inject([]){ |schedules, interval| schedules + interval.schedules }
        @booked_schedules = booked_intervals.inject([]){ |schedules, interval| schedules + interval.schedules }
      end

      after do
        Timecop.return
      end

      it 'adds the service booked schedules to the availability' do
        finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find

        expect(aliadas_availability.schedules.map(&:id).uniq.sort).to eql @available_schedules.map(&:id).sort

        finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: true, periodicity: 7, service: service)
        aliadas_availability = finder.find

        expect(aliadas_availability.schedules.map(&:id).uniq.sort).to eql (@available_schedules.map(&:id) + @booked_schedules.map(&:id)).sort
      end
    end

    describe 'calculates the availability taking in account business hours ' do
      context 'for one time services' do
        it 'takes into account for the availability the start of aliada day' do
          create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zone: zone} )

          availability = AvailabilityForCalendar.find_availability(3, zone, starting_datetime, recurrent: false)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 1

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 3.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4
        end

        it 'takes into account for the availability the end of aliada day' do
          create_one_timer!(starting_datetime + 10.hours, hours: 4, conditions: {aliada: aliada, zone: zone} )

          availability = AvailabilityForCalendar.find_availability(3, zone, starting_datetime, recurrent: false)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 1

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 10.hours
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 13.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4
        end

        it 'takes into account for the availability the end and the start of aliada day' do
          create_one_timer!(starting_datetime + 3.hours, hours: 4, conditions: {aliada: aliada, zone: zone} )

          availability = AvailabilityForCalendar.find_availability(4, zone, starting_datetime, recurrent: false)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 1

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 3.hours
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 6.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4
        end
      end

      context 'for recurrent services' do
        it 'returns smaller intervals when these start at the beginning_of_aliadas_day' do

        end

        it 'returns smaller intervals when these end at the end_of_aliadas_day' do

        end
      end
    end
  end
end
