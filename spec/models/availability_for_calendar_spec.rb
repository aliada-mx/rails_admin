# -*- encoding : utf-8 -*-
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
      Timecop.freeze(starting_datetime)
    end

    after do
      Timecop.return
    end

    context 'for a one time service' do
      before do

        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zones: [zone]} )
        create_one_timer!(starting_datetime + 4.hours, hours: 4, conditions: {aliada: aliada_2, zones: [zone]} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @finder = AvailabilityForCalendar.new(3, zone, starting_datetime)
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
        Schedule.where(datetime: starting_datetime + 1.hour, aliada: aliada).map(&:book)

        finder = AvailabilityForCalendar.new(3, zone, starting_datetime)
        aliadas_availability = finder.find

        expect(aliadas_availability.size).to be 1
        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada_2.id }).to be true
      end

      it 'it finds availability when at least one aliada has it for a specific hour' do
        Schedule.where(aliada_id: [aliada_2.id]).map(&:book)
        finder = AvailabilityForCalendar.new(3, zone, starting_datetime)

        aliadas_availability = finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)

        expect(aliadas_availability.size).to be 1
        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
      end

      it 'doesnt find an available datetime when are requested more hours than the available schedules' do
        aliadas_availability = AvailabilityForCalendar.new(8, zone, starting_datetime).find
        
        expect(aliadas_availability).to be_empty
      end

      it 'adds the service future schedules to the avalability' do
        aliadas_availability = AvailabilityForCalendar.new(8, zone, starting_datetime).find
      end

      it 'finds smaller availability at the end of the day' do
        # create_one_timer!(starting_datetime)

      end
    end

    context 'for a recurrent service ' do

      before do
        Timecop.freeze(starting_datetime)

        create_recurrent!(starting_datetime,           hours: 5, periodicity: 7, conditions: {aliada: aliada, zones: [zone]} )
        create_recurrent!(starting_datetime + 4.hours, hours: 5, periodicity: 7, conditions: {aliada: aliada_2, zones: [zone]} )

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

        expect(aliadas_availability.size).to be 2
        expect(aliadas_availability.schedules_intervals.size).to be 30
        expect(aliadas_availability.schedules.size).to be 120

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)

        expect(aliada_1_availability.schedules_intervals.size).to be 15
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.size).to be 15
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 4.hours + 7.days, aliada_id: aliada_2).map(&:book)
        finder = AvailabilityForCalendar.new(5, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 1

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

        finder = AvailabilityForCalendar.new(5, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 1

        expect(aliadas_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
        expect(aliadas_availability.schedules_intervals.any? { |interval| interval.aliada_id == aliada_2.id }).to be false
      end

      it 'finds the summed availability of all aliadas even if they have the same availabilites' do
        create_recurrent!(starting_datetime + 4.hours, hours: 5, periodicity: 7, conditions: {aliada: aliada_3, zones: [zone]} )

        finder = AvailabilityForCalendar.new(4, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find

        expect(aliadas_availability.size).to be 3
        expect(aliadas_availability.schedules_intervals.size).to be 30

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.size).to be 10
        
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_2_availability.schedules_intervals.size).to be 10

        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 4.hour
        expect(aliada_3_availability.schedules_intervals.size).to be 10

        expect(aliada_3_availability.schedules.map(&:datetime).sort).to eql aliada_2_availability.schedules.map(&:datetime).sort
      end

      it 'find smaller availability at end of the day' do
        create_recurrent!(starting_datetime + 5.hours, hours: 2, periodicity: 7, conditions: {aliada: aliada, zones: [zone]} )

        finder = AvailabilityForCalendar.new(4, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 2
        expect(aliadas_availability.schedules_intervals.size).to be 30

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)

        expect(aliada_1_availability.schedules_intervals.size).to be 20
        
        expect(aliada_2_availability.schedules_intervals.size).to be 10
      end
    end

    context 'with a pre chosen aliada' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zones: [zone]} )
        create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada_2, zones: [zone]} )

        @finder = AvailabilityForCalendar.new(4, zone, starting_datetime, aliada_id: aliada.id)
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
        available_intervals = create_recurrent!(starting_datetime + 1.day, hours: 3, periodicity: 7, conditions: {aliada: aliada, zones: [zone], status: 'available'} )
        @available_schedules = available_intervals.inject([]){ |schedules, interval| schedules + interval.schedules }

        booked_intervals = create_recurrent!(starting_datetime + 3.hours + 1.day, hours: 1, periodicity: 7, conditions: {aliada: aliada, zones: [zone], service: service, status: 'booked'} )
        @booked_schedules = booked_intervals.inject([]){ |schedules, interval| schedules + interval.schedules }
      end

      after do
        Timecop.return
      end

      it 'adds the service booked schedules to the availability' do
        finder = AvailabilityForCalendar.new(4, zone, starting_datetime, recurrent: true, periodicity: 7)
        aliadas_availability = finder.find

        expect(aliadas_availability).to be_empty

        finder = AvailabilityForCalendar.new(4, zone, starting_datetime, recurrent: true, periodicity: 7, service: service)
        aliadas_availability = finder.find

        expect(aliadas_availability.schedules.map(&:id).uniq.sort).to eql (@available_schedules.map(&:id) + @booked_schedules.map(&:id)).sort
      end
    end

    describe 'calculates the availability taking in account business hours ' do
      context 'for one time services' do
        it 'takes into account for the availability the start of aliada day' do
          create_one_timer!(starting_datetime, hours: 4, conditions: {aliada: aliada, zones: [zone]} )

          finder = AvailabilityForCalendar.new(3, zone, starting_datetime, recurrent: false)
          availability = finder.find

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 2

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 3.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4
        end

        it 'takes into account for the availability the end of aliada day' do
          create_one_timer!(starting_datetime + 10.hours, hours: 4, conditions: {aliada: aliada, zones: [zone]} )

          availability = AvailabilityForCalendar.find_availability(3, zone, starting_datetime, recurrent: false)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 2

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 10.hours
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 13.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4

          expect(aliada_1_availability.schedules_intervals.second.beginning_of_interval).to eql starting_datetime + 11.hours
          expect(aliada_1_availability.schedules_intervals.second.ending_of_interval).to eql starting_datetime + 13.hours
          expect(aliada_1_availability.schedules_intervals.second.size).to be 3
        end

        it 'takes into account for the availability the end and the start of aliada day' do
          create_one_timer!(starting_datetime + 3.hours, hours: 4, conditions: {aliada: aliada, zones: [zone]} )

          availability = AvailabilityForCalendar.find_availability(4, zone, starting_datetime, recurrent: false)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 1

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 3.hours
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 6.hours
          expect(aliada_1_availability.schedules_intervals.first.size).to be 4
        end
      end

      context 'for recurrent services' do
        it 'takes into account for the availability the end and the start of aliada day' do
          create_recurrent!(starting_datetime + 3.hours, hours: 4, periodicity: 7, conditions: {aliada: aliada, zones: [zone]} )

          availability = AvailabilityForCalendar.find_availability(4, zone, starting_datetime, recurrent: true, periodicity: 7)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 5

          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime + 3.hours
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 6.hours
          expect(aliada_1_availability.schedules_intervals.map(&:size)).to eql [4,4,4,4,4]
        end
      end

      context 'with a service booked in front' do
        it 'find availability with 2 padding hours in front' do
          create_one_timer!(starting_datetime, hours: 8, conditions: {aliada: aliada, zones: [zone]} )
          Schedule.ordered_by_aliada_datetime.to_a[-2..-1].map(&:book!)

          availability = AvailabilityForCalendar.find_availability(4, zone, starting_datetime, periodicity: 7)

          aliada_1_availability = availability.for_aliada(aliada)

          expect(aliada_1_availability.schedules_intervals.size).to be 1
          expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
          expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 5.hours
        end
      end
    end
  end
end
