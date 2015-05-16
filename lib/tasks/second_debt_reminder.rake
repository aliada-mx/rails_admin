namespace :db do
  desc "Second debt reminder"
  task :second_debt_reminder => :environment do
    cwd = Dir.pwd
    relative_path = './lib/tasks/data/second_reminder_debts.csv'
    absolute_path = File.join(cwd, relative_path)
   
    data = CSV.read(absolute_path)
   
    total = 0
    data[1..-1].each do |row|
      user = User.find_by_email row.second.strip
      user.send_second_debt_reminder_email
      total += 1
    end
    puts "#{total} emails sent"
  end
end
