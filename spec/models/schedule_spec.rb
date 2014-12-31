require 'test_helper'

describe 'Schedule' do
  let!(:service) { create(:service) }
  let!(:zone) { create(:zone) }
  let!(:aliada) { create(:aliada) }
  let!(:schedule) { create(:schedule, 
                          zone: zone,
                          service: service,
                          user: aliada) }

  describe '#available_in_zone' do
    it 'should be listed as available' do
      expect(Schedule.available_in_zone(zone).pluck(:id)).to include(schedule.id)
    end
  end
end
