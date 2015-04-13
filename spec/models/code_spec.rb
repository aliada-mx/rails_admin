# -*- encoding : utf-8 -*-
describe 'Code' do
  let!(:user){ create(:user) }
  let!(:other_user){ create(:user) }
  let!(:code_type){ create(:code_type) }

  describe '#code creation' do

    before do
      user.create_promotional_code code_type      
      other_user.create_promotional_code code_type      
    end

    it 'should create a code for the user' do
      expect(user.code).to be_present
      expect(other_user.code).to be_present
      expect(user.code).not_to eq other_user.code
      # The code generated for only the client user 
      expect(Code.count).to be 2
    end

    it 'should throw error on duplicate code name' do
      user.code.name = other_user.code.name
      expect {user.code.save!}.to raise_error
    end

    it 'should redeem codes correctly' do
      user.redeem_code other_user.code.name
      expect(user.redeemed_credits.count).to be 1
      expect(user.credits.count).to be 0
      expect(user.redeemed_credits.first.code).to eq other_user.code
      expect(user.redeemed_credits).to eq other_user.credits
    end
  end
end
