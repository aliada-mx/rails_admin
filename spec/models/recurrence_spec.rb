describe 'Recurrence' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }

  let(:aliada){ create(:aliada) }
  let(:recurrence) { build(:recurrence, weekday: starting_datetime.weekday, hour: starting_datetime.hour ) }
  let(:service) { build(:service, estimated_hours: 3, hours_after_service: 2) }

  before do
    Timecop.freeze(starting_datetime)
    6.times do |i|
      create(:schedule, datetime: starting_datetime + i.hours)
    end
  end

  after do
    Timecop.return
  end

  describe '#wday' do
    it 'should be tuesday' do
      expect(recurrence.wday).to eql 4
    end
  end

  describe '#wdays_count_to_end_of_recurrency' do
    it 'returns 5 for the number of thursdays on january 2015' do
      expect(starting_datetime).to eql Time.zone.parse('01 Jan 2015 13:00:00')
      expect(Setting.time_horizon_days).to be 30
      expect(recurrence.wdays_count_to_end_of_recurrency(starting_datetime)).to be 5
    end
  end
end
