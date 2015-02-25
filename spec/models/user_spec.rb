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
end
