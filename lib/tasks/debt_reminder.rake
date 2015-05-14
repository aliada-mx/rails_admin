namespace :db do
  desc "Debt reminder"
  task :debt_reminder => :environment do
	  User.owes_services.each do |user|
      user.send_owed_services_email
    end
  end
end
