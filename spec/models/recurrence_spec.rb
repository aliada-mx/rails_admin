describe 'Recurrence' do
  context 'in utc' do
  
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

  context 'mexico city cst to dst change' do

    let(:cst_starting_datetime) { Time.zone.parse('04 Apr 2015 00:00:00') }
    let(:cst_recurrence) { build(:recurrence, weekday: 'saturday', hour: 7 ) }
    let(:cst_day_change_recurrence) { build(:recurrence, weekday: 'saturday', hour: 18 ) }

    let(:dst_starting_datetime) { Time.zone.parse('05 Apr 2015 00:00:00') }
    let(:dst_recurrence) { build(:recurrence, weekday: 'sunday', hour: 7 ) }
    let(:dst_day_change_recurrence) { build(:recurrence, weekday: 'sunday', hour: 18 ) }

     describe '#utc_weekday and utc_hour' do

      context 'AFTER DST' do

        it 'returns the same UTC hour after the cst to dst change' do
          expect(dst_recurrence.utc_hour(dst_starting_datetime)).to eql 13
          expect(dst_day_change_recurrence.utc_hour(dst_starting_datetime)).to eql 0 
        end

        it 'returns the same UTC weekday after the cst to dst change' do
          expect(dst_recurrence.utc_weekday(dst_starting_datetime)).to eql 'sunday' 
          expect(dst_day_change_recurrence.utc_weekday(dst_starting_datetime)).to eql 'monday' 
        end
      end

      context 'BEFORE DST' do
        it 'returns the same UTC hour before the cst to dst change' do
          expect(cst_recurrence.utc_hour(cst_starting_datetime)).to eql 13
          expect(cst_day_change_recurrence.utc_hour(cst_starting_datetime)).to eql 0
        end

        it 'returns the same UTC weekday before the cst to dst change' do
          expect(cst_recurrence.utc_weekday(cst_starting_datetime)).to eql 'saturday' 
          expect(cst_day_change_recurrence.utc_weekday(cst_starting_datetime)).to eql 'sunday' 
        end
        
      end

    end
    
  end

  context 'recurrence cst to dst change' do
    let(:starting_datetime) { Time.zone.parse('03 Apr 2015 13:00:00').in_time_zone("Mexico City") }
    let(:dst_recurrence) { build(:recurrence, weekday: 'wednesday', hour: 7 ) }
    let(:dst_day_change_recurrence) { build(:recurrence, weekday: 'wednesday', hour: 18 ) }
    let(:cst_recurrence) { build(:recurrence, weekday: 'saturday', hour: 7 ) }
    let(:cst_day_change_recurrence) { build(:recurrence, weekday: 'saturday', hour: 18 ) }

    before do
      Timecop.freeze(starting_datetime)
    end

    describe '#next_recurrence_with_hour_now_in_utc' do

      context 'AFTER DST' do

        it 'returns the same UTC hour after the cst to dst change' do
          expect(dst_recurrence.next_recurrence_with_hour_now_in_utc.hour).to eql 13
          expect(dst_day_change_recurrence.next_recurrence_with_hour_now_in_utc.hour).to eql 0 
        end

        it 'returns the same UTC weekday after the cst to dst change' do
          expect(dst_recurrence.next_recurrence_with_hour_now_in_utc.weekday).to eql 'wednesday' 
          expect(dst_day_change_recurrence.next_recurrence_with_hour_now_in_utc.weekday).to eql 'thursday' 
        end
      end

      context 'BEFORE DST' do
        it 'returns the same UTC hour before the cst to dst change' do
          expect(cst_recurrence.next_recurrence_with_hour_now_in_utc.hour).to eql 13
          expect(cst_day_change_recurrence.next_recurrence_with_hour_now_in_utc.hour).to eql 0
        end

        it 'returns the same UTC weekday before the cst to dst change' do
          expect(cst_recurrence.next_recurrence_with_hour_now_in_utc.weekday).to eql 'saturday' 
          expect(cst_day_change_recurrence.next_recurrence_with_hour_now_in_utc.weekday).to eql 'sunday' 
        end
        
      end

    end 
  end
end
