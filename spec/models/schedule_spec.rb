# -*- encoding : utf-8 -*-
describe 'Schedule' do
  starting_datetime = Time.zone.parse('01 Jan 2015 13:00:00')

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
      expect(Schedule.for_booking(zone, starting_datetime)).not_to be_empty
      expect(Schedule.for_booking(zone, starting_datetime)).to include(schedule)
    end
  end

  describe '#schedule_within_working_hours' do
    it 'validates the schedule datetime is not too early' do
      too_early = Time.zone.now.change(hour: Setting.beginning_of_aliadas_day - 1)

      schedule.datetime = too_early

      expect(schedule).to be_invalid
      expect(schedule.errors.messages).to have_key :datetime
      expect(schedule.errors.messages[:datetime].first).to include 'No podemos registrar una hora de servicio que empieza o termina fuera del horario de trabajo'
    end

    it 'validates the schedule datetime is not too late' do
      too_late = '2014-10-31 04:00:00'.in_time_zone

      schedule.datetime = too_late

      expect(schedule).to be_invalid
      expect(schedule.errors.messages).to have_key :datetime
      expect(schedule.errors.messages[:datetime].first).to include 'No podemos registrar una hora de servicio que empieza o termina fuera del horario de trabajo'
    end
  end
end
