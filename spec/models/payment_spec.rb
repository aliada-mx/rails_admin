# -*- encoding : utf-8 -*-
describe 'Payment' do
  
  describe '#create_from_paypal_charge' do
    let(:user){ create(:user) }
    let(:service) { create(:service, user: user) }
    let(:paypal_charge) { create(:paypal_charge, amount: 100) }

    it 'should create a complete payment' do

      payment = Payment.create_from_paypal_charge(service, paypal_charge)

      expect(payment.user).to eql user
      expect(payment.amount).to eql 100
      expect(payment.payeable).to eql service
      expect(payment.payment_provider).to eql paypal_charge
    end
  end
end
