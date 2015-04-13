namespace :db do
  desc "Fix conekta customer_id "
  task :fix_customer_id => :environment do
    missing_id = []

    User.all.map do |user|
      user.conekta_customer_id ||= user.default_payment_provider.customer_id
      
      if user.conekta_customer_id.nil?
        missing_id.push(user)
        puts user.services
      else
        user.save!
      end
    end

    missing_id.each do |user|
      Ticket.create_warning(category: 'users_without_cards',
                            message: 'El usuario no tiene tarjeta de crédito guardada',
                            relevant_object: user)
    end
  end
end
