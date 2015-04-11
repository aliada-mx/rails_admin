# -*- encoding : utf-8 -*-
describe 'AliadaSupport::DatetimeSupport' do
  let(:object) { Object.new }
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 07:00:00') }

  before do
    object.extend(AliadaSupport::DatetimeSupport)

    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  describe 'all_wdays_until_horizon' do
    it 'returns a valid count of all the weekdays of january 2015' do
      wdays = object.all_wdays_until_horizon(starting_datetime)
      expect(wdays).to eql [4, 4, 4, 4, 5, 5, 4]
    end
  end
end
