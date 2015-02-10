describe 'Aliada' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }
  let(:ending_datetime){ starting_datetime + 6.hour}
  let(:aliada){ create(:aliada) }
  let(:other_aliada){ create(:aliada) }

  describe '#services_on_day' do
    it 'returns an aliada services during all day' do
      service_on_day = create(:service, status: 'aliada_assigned', datetime: starting_datetime + 1.hour)
      service_on_day_2 = create(:service, status: 'aliada_assigned', datetime: starting_datetime + 3.hour)
      service_in_other_day = create(:service, status: 'aliada_assigned', datetime: starting_datetime.yesterday )

      aliada.services << service_on_day
      aliada.services << service_on_day_2
      aliada.save!

      expect(aliada.services_on_day(starting_datetime) - [service_on_day, service_on_day_2]).to be_empty
      expect(aliada.services_on_day(starting_datetime).include? service_in_other_day).to be false
    end
  end

  describe '#free_services_hours' do
    before do
      Timecop.freeze(starting_datetime)
    end

    after do
      Timecop.return
    end

    it 'returns the total work hours until horizon for alidas without services' do
      expect(aliada.busy_services_hours).to be 434
    end

    it 'returns the total work hours minus number of services hours until horizon for alidas' do
      service_1 = create(:service, datetime: starting_datetime, billable_hours: 3)
      service_2 = create(:service, datetime: starting_datetime + 4.hours, billable_hours: 3)
      aliada.services << service_1
      aliada.services << service_2
      expect(aliada.busy_services_hours).to eql 425
    end

    it 'returns the total work hours minus number of services hours until horizon for alidas' do
      service = create(:service, datetime: starting_datetime + 1.hour, billable_hours: 3)
      aliada.services << service
      expect(aliada.busy_services_hours).to eql 429
    end
  end

  describe '#previous_service' do
    it 'returns the service closer in time in the past' do
      first_service_of_the_day = create(:service, datetime: starting_datetime)
      middle_service_of_the_day = create(:service, datetime: starting_datetime + 4.hours)
      current_service = create(:service, datetime: starting_datetime + 9.hours)

      aliada.services << first_service_of_the_day
      aliada.services << middle_service_of_the_day
      aliada.services << current_service

      expect(aliada.previous_service(current_service)).to eql middle_service_of_the_day
    end
  end

  describe '#service_hours' do
    before do
      Timecop.freeze(starting_datetime)
    end

    after do
      Timecop.return
    end
    it 'returns the number of service hours from now on' do
      service_1 = create(:service, datetime: starting_datetime.change(year: 2014))
      service_2 = create(:service, datetime: starting_datetime)
      service_3 = create(:service, datetime: starting_datetime + 5.hours)

      aliada.services << service_1
      aliada.services << service_2
      aliada.services << service_3

      expect(aliada.service_hours).to eql service_2.total_hours + service_3.total_hours
    end
  end
end
