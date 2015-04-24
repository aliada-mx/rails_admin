class Debt < ActiveRecord::Base
  has_paper_trail  

  def charge!
    #When charging debt, we must ensure the service status is set to paid
    #We pass the user charge! the service owed, this abstraction probably 
    #needs refactoring
    self.user.charge!(self.amount, self.payeable)
    
    #if succesful
    self.payeable.finish
    #else do nothing
  end

  ###Pending implement a paid? method so we can quickly determine the debts missing collection

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
