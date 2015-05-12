namespace :db do
  desc "Deduplicate debts"
  task :deduplicate_debts => :environment do
    Service.all.each do |s|
      if s.debts.count > 1
        s.debts.each do |d|
          if d.payment_provider_choice_type.nil?
            d.destroy
          end
        end
      end
    end
  end
end
