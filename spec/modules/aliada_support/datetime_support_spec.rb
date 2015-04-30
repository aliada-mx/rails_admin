# -*- encoding : utf-8 -*-
describe 'AliadaSupport::DatetimeSupport' do
  let(:object) { Object.new }
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }

  before do
    object.extend(AliadaSupport::DatetimeSupport)

    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  describe '#all_wdays_until_horizon' do
    it 'returns a valid count of all the weekdays of january 2015' do
      wdays = object.all_wdays_until_horizon(starting_datetime)
      expect(wdays).to eql [4, 4, 4, 4, 4, 4, 4]
    end
  end

  describe '#starting_datetime_to_book_services' do
    it 'returns tommorrow if now is before the 22 utc' do
      expect(object.starting_datetime_to_book_services).to eql starting_datetime + 1.day
    end

    it 'returns tommorrow if now is after the 22 utc' do
      Timecop.travel(starting_datetime + 10.hours)
    
      expect(object.starting_datetime_to_book_services).to eql starting_datetime + 2.day
    end
  end
end
