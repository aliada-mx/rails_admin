describe 'User' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 16:00:00') }
  let!(:user){ create(:user) }
  let!(:aliada){ create(:aliada) }
  let!(:other_aliada){ create(:aliada) }
  let!(:service){ create(:service, 
                         aliada: aliada,
                         user: user,
                         datetime: starting_datetime) }
  let!(:other_service){ create(:service, 
                               aliada: other_aliada,
                               user: user,
                               datetime: starting_datetime) }
  let!(:conekta_card){ create(:conekta_card) }
  let!(:other_conekta_card){ create(:conekta_card) }

  describe '#past_aliadas' do
    before do
      Timecop.freeze(starting_datetime + 1.hour)
    end
    after do
      Timecop.return
    end

    it 'returns the aliadas on the user services' do
      expect(user.past_aliadas).to eql [aliada, other_aliada]
    end

    it 'sets the default payment provider to the last created' do
      user.create_payment_provider_choice(conekta_card)

      expect(user.default_payment_provider).to eql conekta_card

      user.create_payment_provider_choice(other_conekta_card)

      expect(user.default_payment_provider).to eql other_conekta_card
    end
  end
  
  describe '#charge_service!' do
    it 'Charges the user using the default payment provider' do
      user.create_payment_provider_choice(conekta_card)
      s = Service.create(price: 65,
                         id: 11,
                         service_type_id: 95,
                         address_id: 71,
                         zone_id: 195,
                         status: 'finished',
                         user_id: user.id,
                         begin_time: Time.now,
                         price: 65, 
                         end_time: Time.now + 3.hour,
                         datetime: starting_datetime,
                         estimated_hours: 3)
      #binding.pry

      VCR.use_cassette('conekta_charge', match_requests_on: [:conekta_preauthorization]) do
      user.charge_service!(s.id)
      end
    end
  end
end
