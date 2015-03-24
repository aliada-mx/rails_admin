describe 'AvailabilityForService' do
  include TestingSupport::SchedulesHelper
  include AliadaSupport::DatetimeSupport

  describe '#dates_available' do
    let!(:zone){ create(:zone) }
    let!(:aliada){ create(:aliada) }
    let!(:aliada_2){ create(:aliada) }
    let!(:aliada_3){ create(:aliada) }
    starting_datetime = Time.zone.parse('01 Jan 2015 13:00:00')
    ending_datetime = starting_datetime + 6.hour

    before do
      @user = double(banned_aliadas: [])
      @recurrence = double(periodicity: double(days: 7))
    end

    context 'for a one time service' do
      before do
        Timecop.freeze(starting_datetime)

        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada, zones: [zone]} )
        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada_2, zones: [zone]} )
        create_one_timer!(starting_datetime, hours: 7, conditions: {aliada: aliada_3, zones: [zone]} )

        @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, starting_datetime + 5.hours)

        @service = double(requested_schedules: @schedule_interval,
                          id: 1,
                          estimated_hours: 3,
                          total_hours: 5,
                          user: @user,
                          recurrence: @recurrence,
                          zone: zone,
                          one_timer?: true,
                          periodicity: nil,
                          timezone: 'UTC',
                          recurrent?: false)
        @finder = AvailabilityForService.new(@service, starting_datetime)

        @service_datetime = starting_datetime_to_book_services.change(hour: 7)
      end

      after do
        Timecop.return
      end

      it 'returns a list of schedule intervals with aliadas ids' do
        aliadas_availability = @finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliada_1_availability.size).to be 1
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.size).to be 1

        expect(aliada_2_availability.size).to be 1
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_2_availability.schedules_intervals.size).to be 1

        expect(aliada_3_availability.size).to be 1
        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_3_availability.schedules_intervals.size).to be 1
      end

      it 'doesnt find an available datetime when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 1.hour).map(&:book)
        finder = AvailabilityForService.new(@service, starting_datetime)
        aliadas_availability = finder.find
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = ScheduleInterval.build_from_range(starting_datetime - 1.hour, ending_datetime)
        service = double(requested_schedules: before_availability_schedule_interval,
                         id: 1,
                         estimated_hours: before_availability_schedule_interval.size,
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
        service = double(requested_schedules: after_availability_schedule_interval,
                         id: 1,
                         estimated_hours: after_availability_schedule_interval.size,
                         user: @user,
                         zone: zone,
                         timezone: 'UTC',
                         total_hours: after_availability_schedule_interval.size,
                         recurrent?: false)
        aliadas_availability = AvailabilityForService.find_aliadas_availability(service, starting_datetime)
        
        expect(aliadas_availability).to be_empty
      end

      it 'doesnt find availability for banned aliadas' do
        user = double(banned_aliadas: [aliada_2])

        service = double(requested_schedules: @schedule_interval,
                         id: 1,
                         estimated_hours: @schedule_interval.size,
                         user: user,
                         zone: zone,
                         timezone: 'UTC',
                         total_hours: @schedule_interval.size,
                         recurrent?: false)
        
        aliadas_availability = AvailabilityForService.find_aliadas_availability(service, starting_datetime)

        expect(aliadas_availability.size).to be 2

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliada_1_availability.size).to be 1

        expect(aliada_2_availability.size).to be 0

        expect(aliada_3_availability.size).to be 1
      end
    end

    context 'for a recurrent service' do
      before do
        Timecop.freeze(starting_datetime)

        intervals = create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada, zones: [zone]} )
                    create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_2, zones: [zone]} )
                    create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada_3, zones: [zone]} )

        @service = double(requested_schedules: intervals.first,
                         id: 1,
                          estimated_hours: intervals.first.size,
                          user: @user,
                          recurrence: @recurrence,
                          datetime: @service_datetime,
                          zone: zone,
                          periodicity: 7,
                          total_hours: 5,
                          wdays_count_to_end_of_recurrency: 5,
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

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)

        expect(aliada_1_availability.size).to be 1
        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 4.hours
        expect(aliada_1_availability.schedules_intervals.size).to be 5

        expect(aliada_2_availability.size).to be 1
        expect(aliada_2_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_2_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 4.hours
        expect(aliada_2_availability.schedules_intervals.size).to be 5

        expect(aliada_3_availability.size).to be 1
        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_3_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 4.hours
        expect(aliada_3_availability.schedules_intervals.size).to be 5
      end

      it 'doesnt find availability when the available schedules have holes in the continuity' do
        Schedule.where(datetime: starting_datetime + 7.days, aliada_id: aliada_2).destroy_all
        finder = AvailabilityForService.new(@service, starting_datetime)
        aliadas_availability = finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_3_availability = aliadas_availability.for_aliada(aliada_3)
        
        expect(aliadas_availability.size).to be 2

        expect(aliada_1_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.first.ending_of_interval).to eql starting_datetime + 4.hours
        expect(aliada_1_availability.schedules_intervals.size).to be 5

        expect(aliadas_availability[aliada_2.id]).to be_blank

        expect(aliada_3_availability.schedules_intervals.first.beginning_of_interval).to eql starting_datetime
        expect(aliada_3_availability.schedules_intervals.size).to be 5
      end

      it 'doesnt find an available datetime when the requested hour happens before the available schedules' do
        before_availability_schedule_interval = create_recurrent!(starting_datetime - 1.hour, 
                                                                  hours: 5,
                                                                  periodicity: 7,
                                                                  persist: false,
                                                                  conditions: {aliada: aliada, zones: [zone]} )


        service = double(requested_schedules: before_availability_schedule_interval.first,
                         id: 1,
                         estimated_hours: before_availability_schedule_interval.size,
                         user: @user,
                         recurrence: @recurrence,
                         zone: zone,
                         wdays_count_to_end_of_recurrency: 5,
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
                                                                 conditions: {aliada: aliada, zones: [zone]} )

        service = double(requested_schedules: after_availability_schedule_interval.first,
                         id: 1,
                         estimated_hours: after_availability_schedule_interval.size,
                         user: @user,
                         recurrence: @recurrence,
                         zone: zone,
                         wdays_count_to_end_of_recurrency: 5,
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
                                                           conditions: {aliada: aliada, zones: [zone]} )

        Schedule.where(datetime: starting_datetime, aliada_id: aliada_3.id).last.update(status: 'booked')

        service = double(requested_schedules: availability_schedule_interval.first,
                         id: 1,
                         estimated_hours: availability_schedule_interval.size,
                         user: @user,
                         datetime: @service_datetime,
                         recurrence: @recurrence,
                         zone: zone,
                         periodicity: 7,
                         total_hours: 5,
                         wdays_count_to_end_of_recurrency: 5,
                         recurrent?: true)
        finder = AvailabilityForService.new(service, starting_datetime)
        aliadas_availability = finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)
        aliada_2_availability = aliadas_availability.for_aliada(aliada_2)
        
        expect(aliadas_availability.size).to be 2

        expect(aliada_1_availability.size).to be 1
        expect(aliada_1_availability.schedules.first.datetime).to eql starting_datetime
        expect(aliada_1_availability.schedules_intervals.size).to be 5

        expect(aliada_2_availability.size).to be 1
        expect(aliada_2_availability.schedules.first.datetime).to eql starting_datetime
        expect(aliada_2_availability.schedules_intervals.size).to be 5

        expect(aliadas_availability[aliada_3]).to be_blank
      end
    end

    context 'for both recurrent and one time services' do
      before do
        Timecop.freeze(starting_datetime)

        interval = create_one_timer!(starting_datetime, hours: 5, conditions: {aliada: aliada, zones: [zone]} )
                   create_one_timer!(starting_datetime, hours: 5, conditions: {aliada: aliada_2, zones: [zone]} )

        @service = double(requested_schedules: interval,
                         id: 1,
                          estimated_hours: 5,
                          user: @user,
                          zone: zone,
                          total_hours: interval.size,
                          periodicity: nil,
                          recurrent?: false)

      end

      after do
        Timecop.return
      end

      it "returns availability only for the passed aliada" do
        finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
        aliadas_availability = finder.find

        aliada_1_availability = aliadas_availability.for_aliada(aliada)

        expect(aliada_1_availability.size).to be 1
        expect(aliada_1_availability.schedules_intervals.size).to be 1
        expect(aliada_1_availability.schedules_intervals.all? { |interval| interval.aliada_id == aliada.id }).to be true
      end

      describe '#mark_padding_hours' do
        it 'marks the no schedules as padding if availability occupies the whole day' do
          finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
          aliadas_availability = finder.find

          aliada_1_availability = aliadas_availability.for_aliada(aliada)

          padding_schedules = aliada_1_availability.schedules.select { |schedule| schedule.padding? }

          expect(padding_schedules.size).to be 0
        end

        it 'it marks one schedule as padding if theres 1 hour available at the end of the "real" service' do
          create_one_timer!(starting_datetime + 5.hours, hours: 1, conditions: {aliada: aliada, zones: [zone]})

          finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
          aliadas_availability = finder.find

          aliada_1_availability = aliadas_availability.for_aliada(aliada)

          padding_schedules = aliada_1_availability.schedules.select { |schedule| schedule.padding? }

          expect(padding_schedules.size).to be 1
        end

        it 'it marks 2 schedules as padding if theres 2 hour available at the end of the "real" service' do
          create_one_timer!(starting_datetime + 5.hours, hours: 2, conditions: {aliada: aliada, zones: [zone]})

          finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
          aliadas_availability = finder.find

          aliada_1_availability = aliadas_availability.for_aliada(aliada)

          padding_schedules = aliada_1_availability.schedules.select { |schedule| schedule.padding? }

          expect(padding_schedules.size).to be 2
        end

        it 'it marks 2 schedules as padding if theres 3 hour available at the end of the "real" service' do
          create_one_timer!(starting_datetime + 5.hours, hours: 3, conditions: {aliada: aliada, zones: [zone]})

          finder = AvailabilityForService.new(@service, starting_datetime, aliada_id: aliada.id)
          aliadas_availability = finder.find

          aliada_1_availability = aliadas_availability.for_aliada(aliada)

          padding_schedules = aliada_1_availability.schedules.select { |schedule| schedule.padding? }

          expect(padding_schedules.size).to be 2
        end
      end
    end
  end
end
