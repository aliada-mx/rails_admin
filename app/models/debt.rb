class Debt < ActiveRecord::Base
  has_paper_trail  

  CATEGORIES = [
    ['Cuota de cancelación', 'cancelation_fee'],
    ['Servicio no pagado', 'service'],
  ]

  belongs_to :service
  belongs_to :user
  belongs_to :payment_provider_choice, polymorphic: true

  validates :category, inclusion: {in: CATEGORIES.map{ |pairs| pairs[1] } }

  def charge!
    #When charging debt, we must ensure the service status is set to paid
    #We pass the user charge! the service owed, this abstraction probably 
    #needs refactoring so it truly enables charging any payeable entity
    charge = self.user.charge!(self.amount, self.service)
    
    self.service.pay if charge
  end
  
  def paid?
    self.service.paid?
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
