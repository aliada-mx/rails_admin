describe 'User' do
  let!(:user){ create(:user) }
  let!(:aliada){ create(:aliada) }
  let!(:other_aliada){ create(:aliada) }
  let!(:service){ create(:service, aliada: aliada, user: user) }
  let!(:other_service){ create(:service, aliada: other_aliada, user: user) }

  describe '#aliadas' do
    it 'returns the aliadas on the user services' do
      expect(user.past_aliadas).to eql [aliada, other_aliada]
    end
  end
end
