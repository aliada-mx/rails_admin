describe 'AvailabilityForService' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  describe '#dates_available' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:aliada_2){ create(:aliada) }
    let!(:aliada_3){ create(:aliada) }
    starting_datetime = Time.zone.parse('01 Jan 2015 07:00:00')
    ending_datetime = starting_datetime + 6.hour

    before do
      @user = double(banned_aliadas: [])
      @recurrence = double(periodicity: double(days: 7))
    end

    context 'for a one time service' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime - 1.hour, hours: 7, conditions: {aliada: aliada, zone: zone} )
        create_one_timer!(starting_datetime - 1.hour, hours: 7, conditions: {aliada: aliada_2, zone: zone} )
        create_one_timer!(starting_datetime - 1.hour, hours: 7, conditions: {aliada: aliada_3, zone: zone} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @service = double(to_schedule_intervals: [@schedule_interval],
                          user: @user,
                          recurrence: @recurrence,
                          zone: zone,
                          one_timer?: true,
                          periodicity: nil,
                          timezone: 'UTC',
                          total_hours: @schedule_interval.size,
                          recurrent?: false)
        @finder = AvailabilityForService.new(@service, starting_datetime)

        @service_datetime = starting_datetime_to_book_services(@service.timezone).change(hour: 7)
      end

      after do
        Timecop.return
      end

      it 'finds an available datetime' do
        aliadas_availability = @finder.find

        expect(aliadas_availability).to be_present
      end

      it 'returns a list of schedule intervals with aliadas ids' do
        aliadas_availability = @finder.find

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
        finder = AvailabilityForService.new(@service, starting_datetime)
        aliadas_availability = finder.find
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)
        service = double(to_schedule_intervals: [before_availability_schedule_interval],
                         user: @user,
                         zone: zone,
                         timezone: 'UTC',
                         total_hours: before_availability_schedule_interval.size,
                         recurrent?: false)
        aliadas_availability = AvailabilityForService.new(service, starting_datetime).find
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
        after_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + 7.hour, ending_datetime + 7.hour)
        service = double(to_schedule_intervals: [after_availability_schedule_interval],
                         user: @user,
                         zone: zone,
                         timezone: 'UTC',
                         total_hours: after_availability_schedule_interval.size,
                         recurrent?: false)
        aliadas_availability = AvailabilityForService.find_aliadas_availability(service, starting_datetime)
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find a availability for banned aliadas' do
        user = double(banned_aliadas: [aliada_2])

        service = double(to_schedule_intervals: [@schedule_interval],
                         user: user,
                         zone: zone,
                         timezone: 'UTC',
                         total_hours: @schedule_interval.size,
                         recurrent?: false)
        
        aliadas_availability = AvailabilityForService.find_aliadas_availability(service, starting_datetime)

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

        intervals = create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada, zone: zone} )
                    create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_2, zone: zone} )
                    create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_3, zone: zone} )

        @service = double(to_schedule_intervals: intervals,
                          user: @user,
                          recurrence: @recurrence,
                          datetime: @service_datetime,
                          zone: zone,
                          periodicity: 7,
                          total_hours: 5,
                          recurrent?: true)
        @finder = AvailabilityForService.new(@service, starting_datetime)
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
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 5

        expect(aliadas_availability[aliada_2.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_2.id].size).to be 5

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 5
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 7.days, aliada_id: aliada_2).destroy_all
        finder = AvailabilityForService.new(@service, starting_datetime)
        aliadas_availability = finder.find
        
        expect(aliadas_availability.size).to be 2
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 5

        expect(aliadas_availability[aliada_2.id].size).to be 0

        expect(aliadas_availability[aliada_3.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_3.id].size).to be 5
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = create_recurrent!(starting_datetime - 1.hour, 
                                                                  hours: 5,
                                                                  periodicity: 7,
                                                                  persist: false,
                                                                  conditions: {aliada: aliada, zone: zone} )

        service = double(to_schedule_intervals: before_availability_schedule_interval,
                         user: @user,
                         recurrence: @recurrence,
                         zone: zone,
                         periodicity: 7,
                         total_hours: 5,
                         recurrent?: false)
        aliadas_availability = AvailabilityForService.new(service, starting_datetime).find
        
        expect(aliadas_availability).to be_empty
      end
      
      it 'doesnt find an available datetime when the requested hour happens after the available schedules' do
        after_availability_schedule_interval = create_recurrent!(starting_datetime + 7.hour, 
                                                                 hours: 7,
                                                                 periodicity: 7,
                                                                 persist: false,
                                                                 conditions: {aliada: aliada, zone: zone} )

        service = double(to_schedule_intervals: after_availability_schedule_interval,
                         user: @user,
                         recurrence: @recurrence,
                         zone: zone,
                         periodicity: 7,
                         total_hours: 5,
                         recurrent?: false)
        aliadas_availability = AvailabilityForService.new(service, starting_datetime).find
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find availability when the recurrence is too small(not enough schedules intervals)' do
        availability_schedule_interval = create_recurrent!(starting_datetime, 
                                                           hours: 5,
                                                           periodicity: 7,
                                                           persist: false,
                                                           conditions: {aliada: aliada, zone: zone} )

        Schedule.where(datetime: starting_datetime, aliada_id: aliada_3.id).last.update(status: 'booked')

        service = double(to_schedule_intervals: availability_schedule_interval,
                         user: @user,
                         datetime: @service_datetime,
                         recurrence: @recurrence,
                         zone: zone,
                         periodicity: 7,
                         total_hours: 5,
                         days_count_to_end_of_recurrency: 5,
                         recurrent?: true)
        aliadas_availability = AvailabilityForService.new(service, starting_datetime).find
        
        expect(aliadas_availability.size).to be 2
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 5

        expect(aliadas_availability[aliada_2.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada_2.id].size).to be 5
      end
    end

    context 'with a pre chosen aliada' do
      before do
        Timecop.freeze(starting_datetime)

        interval = create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada, zone: zone} )
                   create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada_2, zone: zone} )

        @service = double(to_schedule_intervals: [interval],
                          user: @user,
                          zone: zone,
                          one_timer?: true,
                          total_hours: interval.size,
                          periodicity: nil,
                          recurrent?: false)
        @finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
      end

      after do
        Timecop.return
      end
      it 'returns only the aliada´s availability' do
        aliadas_availability = @finder.find

        expect(aliadas_availability.size).to be 1
        expect(aliadas_availability[aliada.id].first.beginning_of_interval).to eql starting_datetime
        expect(aliadas_availability[aliada.id].size).to be 1
      end
    end
  end
end
