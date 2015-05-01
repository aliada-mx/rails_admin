namespace :db do
  desc "Associate service with debts"
  task :associate_service_with_debts => :environment do
    def find_conekta_payments(service)
      Payment.where(payment_provider_type: 'ConektaCard',
                    payment_provider_id: service.user.default_payment_provider.id)
    end

    def find_user_credits_payments(service)
      Payment.where(payment_provider: service.user)
    end

    #######Here we associate each payment to a service
    ###find Payments, find services where user id matches
    ### assoc a Matching service to each payment according to price

    puts "debts count #{Debt.all.count}"
    services_with_status_corrected = []
    ActiveRecord::Base.transaction do
      #Fix services, the ones that must be finished
      services = Service.in_the_past.where('aliada_reported_begin_time is not null')
                                    .where("billable_hours = 0")

      for service in services  
        service.status = 'aliada_assigned'
        service.finish
        service.save
      end
      puts "services_finished #{services.count}"

      users = Hash.new{ |h,k| h[k] = [] }
      Service.cobro_fallido.each do |service|
        users[service.user].push service
      end

      banned_changing_balance = [141]
      balance_in_zero = [305]

      total_points = 0
      users.each do |user, services|

        # Sum total owed
        owed_by_services = 0
        services.each do |service|
          if service.canceled?
            owed_by_services += 100
            service.status = 'canceled_out_of_time'
            service.save!
          else
            owed_by_services += service.amount_to_bill
          end
        end

        # Create debt
        services.each do |service|
          if service.amount_to_bill > 0
            category = service.canceled? ? 'cancelation_fee' : 'service'

            puts category
            Debt.find_or_create_by(service: service,
                                   user: user,
                                   amount: service.amount_to_bill,
                                   category: category)
          end
        end

        # Adjust balance
        if banned_changing_balance.include?( user.id  )
          puts "\n"
          next 
        end

        if balance_in_zero.include?( user.id )
          user.points = 0
          user.save!
          next
        end

        if (user.points * -1) == owed_by_services
          user.points = 0
        elsif user.points == owed_by_services
        elsif user.points == 0
        elsif user.points < 0 && ( owed_by_services > user.points * -1 )

          user.points = owed_by_services + user.points
        else
          user.points = 0
        end

        puts "user #{user.name} #{user.id} owes by services #{owed_by_services} and has a balance of #{user.points}"
        puts "\tcambios de balance: \n #{user.list_balance_changes}" if user.list_balance_changes.present?

        total_points += user.points

        user.save
        puts "\n"
      end
      puts "#{ total_points } total_points"

      puts "debts count #{Debt.all.count}"
    end
  end
end
