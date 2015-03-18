describe 'Recurrence' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }

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
end
