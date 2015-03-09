describe 'Recurrence' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 00:00:00') }

  let(:aliada){ create(:aliada) }
  let(:recurrence) { build(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let(:service) { build(:service, estimated_hours: 3, hours_before_service: 2, hours_after_service: 2) }

  before do
    6.times do |i|
      create(:schedule, datetime: starting_datetime + i.hours)
    end
  end

  describe '#wday' do
    it 'should be tuesday' do
      expect(recurrence.wday).to eql 4
    end
  end

  describe '#to_schedule_intervals' do
    before :each do
      Timecop.freeze(starting_datetime)

      @schedule_intervals = recurrence.to_schedule_intervals(6.hours)
    end

    after do
      Timecop.return
    end

    it 'should have valid schedule intervals ending datetimes' do
      expect(@schedule_intervals.first.ending_of_interval.hour).to eql (starting_datetime + 5.hours).hour
    end

    it 'should have a correct number of schedule intervals' do
      expect(@schedule_intervals.size).to eql 4
    end
  end
end
