namespace :db do
  desc "Fix services without recurrences"
  task :fix_services_without_recurrences => :environment do
    services_without_recurrences = Service.not_canceled.in_the_future.where(service_type_id: 1).where(recurrence_id: nil)

    failed_through_schedule = []
    puts 'trying to find the recurrence through the schedules'
    services_without_recurrences.each do |service|
      puts "service #{service.id}"
      # puts "service schedules recurrence ids #{service.schedules.order(:updated_at).in_the_future.map { |s| [ s.recurrence.try(:name), s.recurrence.try(:created_at) ] }}"
      service.schedules.each do |schedule|
        recurrence = schedule.recurrence

        service.recurrence = recurrence if recurrence && recurrence.active?
        service.save!
      end

      if service.recurrence_id.nil?
        failed_through_schedule.push service
      end
    end

    puts "failed #{failed_through_schedule} through schedule"

    puts 'trying to find the recurrence with the service datetime'
    failed_through_datetime = []

    failed_through_schedule.each do |service|
      datetime = service.tz_aware_datetime
      hour = datetime.hour
      weekday = datetime.weekday
      user = service.user
      aliada_id = service.aliada_id

      recurrence = Recurrence.find_by(user: user, hour: hour, weekday: weekday, aliada_id: aliada_id, status: 'active')

      if recurrence
        service.recurrence = recurrence
        service.save!
      else
        failed_through_datetime.push service
      end
    end
    "#{ failed_through_datetime.size } failed_through_datetime"


    failed_through_datetime.each do |service|
      service.cancel
    end
  end
end

services_without_recurrences = [ 
[ 'https://aliada.mx/perfil/717/visitas-proximas', 3465 ],
[ 'https://aliada.mx/perfil/299/visitas-proximas', 3424 ],
[ 'https://aliada.mx/perfil/502/visitas-proximas', 3454 ],
[ 'https://aliada.mx/perfil/659/visitas-proximas', 3458 ],
[ 'https://aliada.mx/perfil/651/visitas-proximas', 3462 ],
[ 'https://aliada.mx/perfil/553/visitas-proximas', 3464 ],
[ 'https://aliada.mx/perfil/281/visitas-proximas', 3471 ],
[ 'https://aliada.mx/perfil/281/visitas-proximas', 3472 ],
[ 'https://aliada.mx/perfil/503/visitas-proximas', 3473 ],
[ 'https://aliada.mx/perfil/591/visitas-proximas', 3474 ],
[ 'https://aliada.mx/perfil/616/visitas-proximas', 3475 ],
[ 'https://aliada.mx/perfil/661/visitas-proximas', 3476 ],
[ 'https://aliada.mx/perfil/731/visitas-proximas', 3478 ],
[ 'https://aliada.mx/perfil/573/visitas-proximas', 3481 ],
[ 'https://aliada.mx/perfil/827/visitas-proximas', 3651 ],
[ 'https://aliada.mx/perfil/406/visitas-proximas', 3673 ],
[ 'https://aliada.mx/perfil/419/visitas-proximas', 3675 ],
[ 'https://aliada.mx/perfil/323/visitas-proximas', 3677 ],
[ 'https://aliada.mx/perfil/708/visitas-proximas', 3681 ],
[ 'https://aliada.mx/perfil/740/visitas-proximas', 3682 ],
[ 'https://aliada.mx/perfil/694/visitas-proximas', 3684 ],
[ 'https://aliada.mx/perfil/728/visitas-proximas', 3688 ],
[ 'https://aliada.mx/perfil/729/visitas-proximas', 3756 ],
[ 'https://aliada.mx/perfil/850/visitas-proximas', 3883 ],
[ 'https://aliada.mx/perfil/824/visitas-proximas', 3895 ],
[ 'https://aliada.mx/perfil/218/visitas-proximas', 3897 ],
[ 'https://aliada.mx/perfil/229/visitas-proximas', 3898 ],
[ 'https://aliada.mx/perfil/663/visitas-proximas', 3908 ],
[ 'https://aliada.mx/perfil/521/visitas-proximas', 3915 ],
[ 'https://aliada.mx/perfil/486/visitas-proximas', 3946 ],
[ 'https://aliada.mx/perfil/651/visitas-proximas', 3929 ],
[ 'https://aliada.mx/perfil/465/visitas-proximas', 3933 ],
[ 'https://aliada.mx/perfil/724/visitas-proximas', 3961 ],
[ 'https://aliada.mx/perfil/664/visitas-proximas', 3965 ],
[ 'https://aliada.mx/perfil/338/visitas-proximas', 3972 ],
[ 'https://aliada.mx/perfil/726/visitas-proximas', 3690 ],
[ 'https://aliada.mx/perfil/651/visitas-proximas', 3697 ],
[ 'https://aliada.mx/perfil/729/visitas-proximas', 3873 ]]
