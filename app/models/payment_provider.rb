# -*- encoding : utf-8 -*-
class PaymentProvider < ActiveRecord::Base
  self.abstract_class = true
  
  def register_payment_failure(product,user,service, message)
    Debt.find_or_create_by(user_id: user.id, 
                           amount: product.amount, 
                           status: "Charge failed #{message}", 
                           payment_provider_choice_id: user.default_payment_provider.id, 
                           payeable_id: service.id,
                           payeable_type: service.class.name)
  end

end
