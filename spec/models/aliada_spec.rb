describe 'Aliada' do
  let(:starting_datetime){ Time.zone.now.change({hour: 13})}
  let(:ending_datetime){ starting_datetime + 6.hour}
  let(:aliada){ create(:aliada) }
  let(:other_aliada){ create(:aliada) }

  describe '#filter_broken_recurrency' do
    before do
      @periodicity = 1.day.to_i
      @schedule_interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime)
      @continuous_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + @periodicity, ending_datetime + @periodicity)
      @discountinuous_schedule_interval = ScheduleInterval.build_from_range(starting_datetime + @periodicity + 1.hour, ending_datetime + @periodicity + 1.hour)

      @continuous_aliadas_availability = {aliada.id => [@schedule_interval, @continuous_schedule_interval] }
      @discontinuous_aliadas_availability = {aliada.id => [@schedule_interval, @continuous_schedule_interval, @discountinuous_schedule_interval],
                                             other_aliada.id => [@schedule_interval, @continuous_schedule_interval] }
    end

    it 'ignores continues intervals' do
      filtered = Aliada.filter_broken_recurrency(@continuous_aliadas_availability, @periodicity)

      expect(filtered[aliada.id]).to include @schedule_interval
      expect(filtered[aliada.id]).to include @continuous_schedule_interval
    end

    it 'filters out discontinues intervals' do
      filtered = Aliada.filter_broken_recurrency(@discontinuous_aliadas_availability, @periodicity)

      expect(filtered[aliada.id]).to be_nil
      expect(filtered[other_aliada.id]).to be_present
    end
  end
end
