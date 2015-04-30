feature 'AliadaWorkingHour' do
  include TestingSupport::SchedulesHelper

  let(:starting_datetime) { Time.zone.parse('2015-04-28 13:00:00 UTC') } # 7 am Mexico City

  let!(:aliada) { create(:aliada) } 
  let!(:monday_7_awh) { create(:aliada_working_hour,
                               status: 'active',
                               hour: 7,
                               aliada: aliada,
                               weekday: 'monday') } 

  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  describe '#mass_disable' do
    it 'deletes the disabled recurrences' do
      create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada, aliada_working_hour: monday_7_awh})

      disabled_recurrences = [ {hour: 7, weekday: 'monday'} ]

      expect( Schedule.count ).to be 20

      AliadaWorkingHour.mass_disable(aliada.id, disabled_recurrences )
      
      expect( Schedule.count ).to be 0
    end
  end

  describe 'mass_create' do
    it 'creates the schedules and the awh until the horizon' do
      # Clear the previous so we can catch this one with certainty
      monday_7_awh.destroy!
       
      new_recurrences = [ {hour: 8, weekday: 'monday'} ]

      AliadaWorkingHour.mass_create(aliada.id, new_recurrences)

      expect( Schedule.count ).to be 4
      aliada_working_hour = AliadaWorkingHour.first

      expect(aliada_working_hour.hour).to be 8
      expect(aliada_working_hour.weekday).to eql 'monday'
    end
  end

  describe 'mass_activate' do
    before do
      monday_7_awh.deactivate!
    end

    it 'activates the working hours until horizon and enables them' do
      awh_to_activate = [ {hour: 7, weekday: 'monday'} ]

      AliadaWorkingHour.mass_activate(aliada.id, awh_to_activate)

      expect( monday_7_awh.reload ).to be_active
    end
  end
end
