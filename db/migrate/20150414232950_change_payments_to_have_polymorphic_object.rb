class ChangePaymentsToHavePolymorphicObject < ActiveRecord::Migration
  def change
    change_table :payments do |t|
      t.references :payeable, polymorphic: true, index: true
    end    
  end

  def datacallback
    #######Here we associate each payment to a service
    ###find Payments, find services where user id matches
    ### assoc a Matching service to each payment according to price
    
    #Fix services, the ones that dont have enabled
    services = Service.in_the_past.not_canceled.where("status != 'paid'").where("status != 'finished'")
    services_to_fix = []
    for s in services  
      if s.billable_hours && (s.billable_hours > 0)
        services_to_fix << s
      elsif s.reported_hours
        services_to_fix << s
      end
    end
    
    services_to_charge = Service.finished
    sum = 0
    for s in services_to_charge
      sum = sum + 1
    end
    
    ##saca el balance de cada usuario
    User.all.each do |u|
      services = Service.where(user_id: u.id, status: 'finished')
      monto_debido = 0
      services.each do |se|
        monto_debido = se.amount_to_bill + monto_debido 
      end

      services_paid = Service.where(user_id: u.id, status: 'paid')
      monto_debido = 0
      services_paid.each do |se|
        monto_debido = se.amount_to_bill + monto_debido 
      end

      payments = Payment.where(user_id: u.id)
      monto_pagado = 0
      payments.each do |p|
        monto_pagado = monto_pagado + p.amount
      end
      puts "#{u.full_name}, debe: #{monto_debido}, pago: #{monto_pagado}, total:#{monto_debido - monto_pagado}"
    end

    payments = Payment.all;nil
    payments.each do |p|
      services = Service.where(user_id: p.user_id);nil
      if services
        services.each do |s|
          if(s.cancelation_fee_charged)
            puts  100
            break;
          elsif(p.amount == s.amount_to_bill)
            puts 'found'
            break;
          else
            puts 'not_found'
          end
        end
      end
    end

  end
  
end
