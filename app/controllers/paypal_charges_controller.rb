# -*- encoding : utf-8 -*-
class PaypalChargesController < ApplicationController
  include PaypalChargeHelper
  protect_from_forgery except: :paypal_ipn

  before_filter :set_user

  # Paypal express url
  def get_redirect_url
    services = params[:services_ids].inject([]) do |services_ids, service_id|
      services_ids.push @user.services.find(params[:service_id])
    end

    render json: { status: :success, paypal_pay_url: paypal_redirect_url(services) }
  end

  def paypal_ipn
    PaypalIpn.create!(api_raw_response: request.raw_post)
    render nothing: true
  end

  def paypal_return
    if params[:subaction] == 'paypal_success'
      paypal_charge = PaypalCharge.create_from_paypal_response(params)

      if paypal_charge && paypal_charge.paid?
        service = paypal_charge.service

        payment = Payment.create_from_paypal_charge(service, paypal_charge) 

        payment.pay
        service.pay
        redirect_to previous_services_users_url(@user, subaction: :paypal_success, service_paid_id: service.id)
      else
        redirect_to previous_services_users_url(@user, subaction: :paypal_cancelation)
      end
    elsif params[:subaction] == 'paypal_cancelation'
      redirect_to previous_services_users_url(@user, subaction: :paypal_cancelation)
    end
  end

  private
    def set_user
      @user = User.find(params[:user_id]) if params.include? :user_id
    end

    def paypal_redirect_url(services)
      paypal_options = {
        no_shipping: true, # if you want to disable shipping information
        allow_note: false, # if you want to disable notes
        pay_on_paypal: true # if you don't plan on showing your own confirmation step
      }

      payment_request, request = build_paypal_requests(services)

      response = request.setup(
        payment_request,
        paypal_return_users_url(service.user, subaction: :paypal_success, service_id: service.id),
        paypal_return_users_url(service.user, subaction: :paypal_cancelation, service_id: service.id),
        paypal_options  # Optional
      )

      response.redirect_uri
    end
end
