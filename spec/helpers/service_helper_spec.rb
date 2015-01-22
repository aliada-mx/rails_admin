RSpec.describe ServiceHelper, :type => :helper do
  describe 'suggest address' do
    let!(:user) { create(:user) }
    let!(:postal_code) { create(:postal_code, code: '11800') }
    let!(:other_postal_code) { create(:postal_code, code: '11800') }
    let!(:address) { create(:address, user: user, postal_code: postal_code) }

    it 'returns the a address with the same postal code' do
      expect(helper.suggest_address(user, postal_code)).to eq(address)
    end

    it 'returns the a new address' do
      expect(helper.suggest_address(user, other_postal_code).attributes).to eq(Address.new.attributes)
    end
  end
end

