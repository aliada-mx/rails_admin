class Debt < ActiveRecord::Base
  has_paper_trail  

  def charge!
    #When charging debt, we must ensure the service status is set to paid
    #We pass the user charge! the service owed, this abstraction probably 
    #needs refactoring so it truly enables charging any payeable entity
    #however if we passed the debt as payeable,
    # then it would keep generating debt endlessly
    charge = self.user.charge!(self.amount, self.payeable)
    
    if charge
    self.payeable.pay
    end
      
  end
  
  
  def paid?
    self.payeable.paid?
  end
 

  rails_admin do
    label_plural 'Deudas'
    parent User
    
    configure :amount do
      sortable true
    end

    list do 
      sort_by :amount
    end
  end
end
