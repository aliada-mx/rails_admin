class PaypalIpn < ActiveRecord::Base

  rails_admin do
    label_plural 'Notificaciones de pago de Paypal'
    parent PaymentMethod
  end
end
