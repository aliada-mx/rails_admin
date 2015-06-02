module PaypalChargeHelper
  def self.included(base)
    base.extend(PaypalChargeHelper)
  end

  def build_paypal_requests(services)
    services_ids = services.pluck(:id).join(', ')
    services_amount = services.inject(0){ |sum,service| sum += service.amount_to_bill }
    services_description = "Servicio#{ services.count > 1 ? 's' : ''} de aliada #{services_ids}"

    payment_request = Paypal::Payment::Request.new(
      :currency_code => :MXN,   # if nil, PayPal use USD as default
      :description   => services_description,
      :quantity      => services.count,
      :amount        => services_amount,
    )

    request = Paypal::Express::Request.new(
      username: Rails.application.secrets.paypal_api_user,
      password: Rails.application.secrets.paypal_api_password,
      signature: Rails.application.secrets.paypal_api_signature,
      sandbox: Setting.paypal_sandbox,
      notify_url: Rails.application.routes.url_helpers.paypal_ipn_url(host: Setting.host),
      NOTIFYURL: Rails.application.routes.url_helpers.paypal_ipn_url(host: Setting.host),
      NotifyURL: Rails.application.routes.url_helpers.paypal_ipn_url(host: Setting.host),
      ipnNotificationUrl: Rails.application.routes.url_helpers.paypal_ipn_url(host: Setting.host),
      custom: services_ids
    )

    [ payment_request, request ]
  end
end
