module PaypalChargeHelper
  def self.included(base)
    base.extend(PaypalChargeHelper)
  end

  def build_paypal_requests(service)
    payment_request = Paypal::Payment::Request.new(
      :currency_code => :MXN,   # if nil, PayPal use USD as default
      :description   => service.description,    # item description
      :quantity      => 1,      # item quantity
      :amount        => service.amount,   # item value
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
      custom: service.id.to_s
    )

    [ payment_request, request ]
  end
end
