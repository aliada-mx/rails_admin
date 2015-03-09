describe 'Schedule' do
  starting_datetime = Time.zone.parse('01 Jan 2015 07:00:00')

  let!(:service) { create(:service) }
  let!(:zone) { create(:zone) }
  let!(:aliada) { create(:aliada) }
  let!(:schedule) { create(:schedule, 
                           datetime: starting_datetime,
                           zone: zone,
                           service: service,
                           aliada: aliada) }
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  describe '#available_for_booking' do
    it 'should be listed as available' do
      expect(Schedule.available_for_booking(zone, starting_datetime)).not_to be_empty
      expect(Schedule.available_for_booking(zone, starting_datetime)).to include(schedule)
    end
  end
end
