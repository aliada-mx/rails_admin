feature 'AliadaWorkingHour' do
  include TestingSupport::SchedulesHelper

  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') } # 7 am Mexico City

  let!(:aliada) { create(:aliada) } 
  let!(:monday_7_awh) { create(:aliada_working_hour,
                               status: 'active',
                               hour: 7,
                               aliada: aliada,
                               weekday: 'monday') } 

  before do
    Timecop.freeze(starting_datetime)

    create_recurrent!(starting_datetime, hours: 5, periodicity: 7, conditions: {aliada: aliada, aliada_working_hour: monday_7_awh})

    @disabled_recurrences = [ {hour: 7, weekday: 'monday'} ]
  end

  after do
    Timecop.return
  end

  describe '#update_from_admin' do
    it 'deletes the disabled recurrences' do
      expect( Schedule.count ).to be 25

      AliadaWorkingHour.update_from_admin(aliada.id, [], @disabled_recurrences, [] )
      
      expect( Schedule.count ).to be 0
    end
  end
end
