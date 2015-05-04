# -*- encoding : utf-8 -*-
class PaymentProvider < ActiveRecord::Base
  self.abstract_class = true
  
  def register_debt(product, user, service)
    Debt.find_or_create_by(user_id: user.id, 
                           amount: product.amount, 
                           category: product.category, 
                           payment_provider_choice: user.default_payment_provider_choice, 
                           service: service)
  end

end
