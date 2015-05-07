namespace :db do
  desc "clean duplicated scores"
  task :clean_duplicated_scores => :environment do

    ActiveRecord::Base.transaction do
      scores_to_keep = {}

      Service.all.each do |service|
        if service.scores.any?
          scores_to_keep[service.scores.last.id] = true
        end
      end

      scores_to_destroy = Score.where('id NOT IN (?)',scores_to_keep.keys())

      puts "#{scores_to_destroy.count} scores_to_destroy"
      puts "#{scores_to_keep.count} scores_to_keep"

      scores_to_destroy.destroy_all
    end
  end
end
