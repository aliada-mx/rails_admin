class Debt < ActiveRecord::Base
  has_paper_trail  

  def charge!
    self.user.charge!(self.amount, self)
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
