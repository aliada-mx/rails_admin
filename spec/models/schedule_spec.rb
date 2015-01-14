describe 'Schedule' do
  let!(:service) { create(:service) }
  let!(:zone) { create(:zone) }
  let!(:aliada) { create(:aliada) }
  let!(:schedule) { create(:schedule, 
                          zone: zone,
                          service: service,
                          aliada: aliada) }

  describe '#available_in_zone' do
    it 'should be listed as available' do
      expect(Schedule.available.in_zone(zone)).not_to be_empty
      expect(Schedule.available.in_zone(zone).pluck(:id)).to include(schedule.id)
    end
  end
end
