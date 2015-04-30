namespace :db do
    desc "Fix too small recurrences"
    task :fix_too_small_recurrences => :environment do

        failed = []
        fixed = 0
        ActiveRecord::Base.transaction do
            broken_recurrences = []

            Recurrence.active.all.each do |recurrence|
                if recurrence.services_for_user.count <= 3
                    broken_recurrences.push recurrence
                end
            end

            puts "there are #{broken_recurrences.size} incomplete recurrences"

            broken_recurrences.each do |recurrence|
               begin
                   puts "before fixing there are #{recurrence.services_for_user.count} services_for_user"
                   next_recurrence_datetime = recurrence.next_recurrence_with_hour_now_in_utc
                   puts "next_recurrence_datetime #{next_recurrence_datetime.weekday} weekday (#{recurrence.weekday})#{next_recurrence_datetime.hour} hour #{recurrence.hour}"
                   recurrence.datetime = next_recurrence_datetime 
                   recurrence.reschedule!(recurrence.aliada_id)
                   puts "recurrence #{recurrence.id} services count #{recurrence.services_for_user.count} recurrence aliada_id #{recurrence.aliada_id} services aliadas id #{recurrence.services_for_user.map { |s| s.aliada_id }}"
                   puts "\n" 
                   fixed +=1
               rescue AliadaExceptions::AvailabilityNotFound
                   failed.push recurrence
               end 
            end
        end

        failed.each do |recurrence|
            puts "https://aliada.mx/perfil/#{recurrence.user.id}/visitas-proximas" 
            puts "weekday #{ recurrence.weekday }" 
            puts "\n" 
        end

        puts "fixed #{fixed}"
        puts "failed #{failed}"


    end
end

<<-eos
        https://aliada.mx/perfil/75/visitas-proximas
        weekday thursday

    https://aliada.mx/perfil/675/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/200/visitas-proximas
    weekday tuesday

        https://aliada.mx/perfil/754/visitas-proximas
        weekday saturday

        https://aliada.mx/perfil/266/visitas-proximas
        weekday thursday

    https://aliada.mx/perfil/859/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/807/visitas-proximas
    weekday monday

        https://aliada.mx/perfil/492/visitas-proximas
        weekday thursday

    https://aliada.mx/perfil/103/visitas-proximas
    weekday monday

        https://aliada.mx/perfil/85/visitas-proximas
        weekday saturday

    https://aliada.mx/perfil/110/visitas-proximas
    weekday sunday

      https://aliada.mx/perfil/336/visitas-proximas
      weekday friday

  https://aliada.mx/perfil/373/visitas-proximas
  weekday thursday

      https://aliada.mx/perfil/408/visitas-proximas
      weekday friday

    https://aliada.mx/perfil/274/visitas-proximas
    weekday monday

      https://aliada.mx/perfil/280/visitas-proximas
      weekday friday

    https://aliada.mx/perfil/479/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/446/visitas-proximas
    weekday monday

      https://aliada.mx/perfil/540/visitas-proximas
      weekday thursday

    https://aliada.mx/perfil/472/visitas-proximas
    weekday saturday

    https://aliada.mx/perfil/552/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/540/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/502/visitas-proximas
    weekday tuesday

    https://aliada.mx/perfil/656/visitas-proximas
    weekday saturday

    https://aliada.mx/perfil/374/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/571/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/627/visitas-proximas
    weekday tuesday

    https://aliada.mx/perfil/686/visitas-proximas
    weekday wednesday

    https://aliada.mx/perfil/701/visitas-proximas
    weekday thursday

    https://aliada.mx/perfil/684/visitas-proximas
    weekday saturday

    https://aliada.mx/perfil/645/visitas-proximas
    weekday wednesday

    https://aliada.mx/perfil/719/visitas-proximas
    weekday saturday

    https://aliada.mx/perfil/679/visitas-proximas
    weekday saturday

    https://aliada.mx/perfil/281/visitas-proximas
    weekday tuesday

    https://aliada.mx/perfil/275/visitas-proximas
    weekday wednesday

    https://aliada.mx/perfil/334/visitas-proximas
    weekday tuesday

    https://aliada.mx/perfil/610/visitas-proximas
    weekday thursday

    https://aliada.mx/perfil/611/visitas-proximas
    weekday tuesday

    https://aliada.mx/perfil/237/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/683/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/673/visitas-proximas
    weekday monday

    https://aliada.mx/perfil/582/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/82/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/573/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/266/visitas-proximas
    weekday thursday

    https://aliada.mx/perfil/200/visitas-proximas
    weekday wednesday

    https://aliada.mx/perfil/533/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/270/visitas-proximas
    weekday friday

    https://aliada.mx/perfil/561/visitas-proximas
    weekday sunday

    https://aliada.mx/perfil/479/visitas-proximas
    weekday thursday
eos
