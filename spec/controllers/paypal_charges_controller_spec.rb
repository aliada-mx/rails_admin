# -*- encoding : utf-8 -*-
feature 'PaypalChargesChargeController' do
  let!(:user) { create(:user) }
  let!(:service) { create(:service, user: user) }

  describe '#get_redirect_url' do
    it 'returns the paypal redirect url' do

      with_rack_test_driver do
        VCR.use_cassette('paypal_redirect_url') do
          page.driver.submit :post, get_paypal_redirect_url_users_url(user.id), { service_id: service.id }
        end
      end

      response = JSON.parse(page.body)

      expect(response['status']).to eql 'success'
      expect(response['paypal_pay_url']).to eql 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-6YK043870V422270N&useraction=commit'
    end
  end

  describe '#paypal_return' do
    let(:params){ 
      {"service_id"=> service.id,
       "subaction"=>"paypal_success",
       "token"=>"EC-68856541M6405552C",
       "PayerID"=>"CVUVAVQWYK9E6",
       "controller"=>"paypal_charges",
       "user_id"=>user.id}
    }
    before do
      expect(service.payments.count).to be 0
      expect(service.paypal_charges.count).to be 0

      login_as(user)
    end

    it 'creates a payment a paypal_charge and marks a service as paid' do
      VCR.use_cassette('paypal_request_info') do
        with_rack_test_driver do
          page.driver.submit :get, paypal_return_users_url(user.id), params
        end
      end
      service.reload

      expect(current_url).to eql previous_services_users_url(service.user, subaction: :paypal_success, service_paid_id: service.id)

      expect(service.paypal_charges.count).to be 1
      paypal_charge = service.paypal_charges.first

      expect(paypal_charge.user).to eql user
      expect(paypal_charge.amount).to eql service.amount
      expect(paypal_charge).to be_paid

      expect(service.payments.count).to be 1
      payment = service.payments.first

      expect(payment.amount).to eql service.amount
      expect(payment.user).to eql user
      expect(payment.payment_provider).to eql paypal_charge
      expect(payment).to be_paid
    end
  end
end
