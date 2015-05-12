# -*- encoding : utf-8 -*-
class PaypalCharge < ActiveRecord::Base
  include PaypalChargeHelper

  belongs_to :user
  belongs_to :service
  belongs_to :payable, polymorphic: true

  def self.create_from_paypal_response(paypal_response)
    token = paypal_response[:token]
    payer_id = paypal_response[:PayerID]
    service = Service.find paypal_response[:service_id]

    begin
      payment_request, request = build_paypal_requests(service)

      response = request.checkout!(
        token,
        payer_id,
        payment_request
      )

      # inspect this attribute for more details
      first_payment = response.payment_info.first
    rescue Paypal::Exception::APIError => exception
      puts exception.message # => 'PayPal API Error'
      puts exception.response # => Paypal::Exception::APIError::Response
      puts exception.response.details # => Array of Paypal::Exception::APIError::Response::Detail. This includes error details for each payment request.

      Raygun.track_exception(exception)
    end

    if first_payment.nil?
      puts request.raw_post
      puts response.inspect
      puts paypal_response
      return nil
    end

    return PaypalCharge.create!(
      ack: first_payment.ack,
      amount: first_payment.amount.total,
      fee: first_payment.amount.fee,
      order_time: first_payment.order_time,
      payment_status: first_payment.payment_status,
      payment_type: first_payment.payment_type,
      receipt_id: first_payment.receipt_id,
      transaction_id: first_payment.transaction_id,
      transaction_type: first_payment.transaction_type,
      api_raw_response: first_payment.inspect,
      user: service.user,
      payable: service
    )
  end

  def paid?
    payment_status == 'Completed'
  end

  def service
    payable
  end

  rails_admin do
    label_plural 'Pagos de Paypal'
    parent PaymentMethod
  end
end
