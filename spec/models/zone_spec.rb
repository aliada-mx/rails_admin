describe 'Zone' do
  let!(:zone) { create(:zone) }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              number: '11800') }

  describe '#find_by_postal_code_number' do
    it 'should find a zone by the postal code' do
      expect(Zone.find_by_postal_code_number('11800')).to eql zone
    end
  end
end
