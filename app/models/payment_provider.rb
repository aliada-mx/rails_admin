# -*- encoding : utf-8 -*-
class PaymentProvider < ActiveRecord::Base
  self.abstract_class = true
  
  def register_debt(user, service)
    debt = Debt.find_or_create_by(user_id: user.id, service: service, amount: service.amount)
    debt.category = service.category
    debt.payment_provider_choice = user.default_payment_provider_choice

    debt.save!
  end
end
