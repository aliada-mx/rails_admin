#!/usr/bin/env ruby
require_relative "../../config/environment"
require 'mysql2' 

connection = Mysql2::Client.new(
  host: ENV["MYSQL_HOST"],
  username: ENV["MYSQL_USER"],
  password: ENV["MYSQL_PASS"],
  database: ENV["MYSQL_DB"],
)

zones = {}
aliadas = {}
clientes = {}
recurrence_with_service = {}
recurrence_with_schedule = {}
servicios = {}

puts "MIGRANDO ZONAS"
connection.query("SELECT * FROM zonas WHERE elim = 0").each do |row|
  zone = Zone.find_or_initialize_by(name: row["nombre"])
  if zone.new_record?
    zone.save
    puts "ZONE #{row["id"]} #{zone.errors.messages.to_yaml}" if not zone.errors.messages.empty?
  end
  if zone.id
    zones[row["id"]] = zone.id
  end
end

puts "MIGRANDO CP"
connection.query("SELECT * FROM cp WHERE elim = 0").each do |row|
  cp = PostalCode.find_or_initialize_by(number: row["cp"].to_s.rjust(5, '0'), name: row["nombre"], zone_id: zones[row["zonas_id"]])
  if cp.new_record?
    cp.save
    puts "POSTALCODE #{row["id"]} #{cp.errors.messages.to_yaml}" if not cp.errors.messages.empty?
  end

end

puts "MIGRANDO ALIADAS"
connection.query("SELECT * FROM aliadas WHERE elim = 0").each do |row|
  row["email"] = "inventado_#{row["id"]}@aliada.com" if row["email"].length == 0
  aliada = Aliada.find_or_initialize_by(first_name: row["nombres"], last_name: row["apellidos"], email: row["email"].downcase, role: "aliada", phone: row["telefono"], created_at: row["created"])
  
  if aliada.new_record?
    aliada.save
    puts "ALIADA #{row["id"]}  #{aliada.errors.messages.to_yaml}" if not aliada.errors.messages.empty?
  end
  if aliada.id
    aliadas[row["id"]] = aliada.id
  end
end

puts "MIGRANDO ALIADAS HAS ZONAS"
connection.query("SELECT * FROM aliadas_has_zonas").each do |row|
  aliada = Aliada.find(aliadas[row["aliadas_id"]]) if aliadas[row["aliadas_id"]]
  aliada.zones.push(Zone.find(zones[row["zonas_id"]])) if (aliada and not aliada.zones.index(Zone.find(zones[row["zonas_id"]])))  
end

puts "MIGRANDO CLIENTES"
connection.query("SELECT * FROM clientes WHERE estatus = 'normal'").each do |row|
  
  first_name = ""
  last_name = ""
  if row["nombre"]
    splitted_name = row["nombre"].split
    first_name = splitted_name[0] 
    last_name = splitted_name[1..splitted_name.length].join(" ") if splitted_name.length > 0
  end
  cliente = User.find_or_initialize_by(first_name: first_name, last_name: last_name, email: row["email"].downcase, role: "client", phone: row["telefono"], created_at: row["created"], credits: row["saldo"] )

  if cliente.new_record?
    cliente.save
    puts "CLIENTE #{row["id"]} #{cliente.errors.messages.to_yaml}" if not cliente.errors.messages.empty?
  end
  if cliente.id
    clientes[row["id"]] = cliente.id
  end
end

puts "MIGRANDO CLIENTES HAS DIRECCIONES"
connection.query("SELECT * FROM (SELECT * FROM clientes_has_direcciones WHERE elim = 0 ORDER BY modified DESC) t GROUP BY t.clientes_id").each do |row|
  
  cp = PostalCode.find_or_create_by(number: row["cp"].to_s.rjust(5, '0'))

  address = Address.find_or_initialize_by(user_id: clientes[row["clientes_id"]], street: row["direccion"], number: row["numero"], interior_number: row["numero_int"], between_streets: row["entre_calles"], colony: row["colonia"], state: row["estado"], city: row["delegacion"], postal_code_id: cp.id,  references: row["referencia"], map_zoom: row["mapa_zoom"]) do |add|
    #treated separately, because decimal objects are different for find_or_create and were duplicating objects
    add.latitude = row["latitud"]
    add.longitude = row["longitud"]
    add.references_latitude = row["referencia_latitud"]
    add.references_longitude = row["referencia_longitud"]
  end

  if address.new_record?
    address.save
    puts "ADDRESS #{row["id"]} #{address.errors.messages.to_yaml}" if not address.errors.messages.empty?
  end
end

puts "MIGRANDO METODOSPAGOS"
connection.query("SELECT * FROM metodospagos ORDER BY created DESC").each do |row|

  if (clientes[row["clientes_id"]])
    cliente = User.find(clientes[row["clientes_id"]])
    conektaCard = ConektaCard.find_or_initialize_by(token: row["TOKEN"], last4: 'XXXX', exp_month: '00', exp_year: '00', active: true, preauthorized: true, customer_id: row["CLIENT_ID"], brand: 'other', name: "#{cliente.first_name} #{cliente.last_name}" )

    if conektaCard.new_record?
      conektaCard.save
      puts "CONEKTACARD #{row["id"]} #{conektaCard.errors.messages.to_yaml}" if not conektaCard.errors.messages.empty?
    end
        

    if cliente.payment_provider_choices.empty? 
      paymentProviderChoice = PaymentProviderChoice.find_or_initialize_by(user_id: cliente.id, payment_provider_id: conektaCard.id, payment_provider_type: "ConektaCard", default: true)
    else
      paymentProviderChoice = PaymentProviderChoice.find_or_initialize_by(user_id: cliente.id, payment_provider_id: conektaCard.id, payment_provider_type: "ConektaCard", default: false)
    end

    if conektaCard.new_record?
      conektaCard.save
      puts "PAYMENTPROVIDERCHOICE #{row["id"]} #{conektaCard.errors.messages.to_yaml}" if not conektaCard.errors.messages.empty?
    end

  end

end

puts "MIGRANDO HORARIOS"
connection.query("SELECT * FROM horarios").each do |row|
  
  if (aliadas[row["aliadas_id"]])
    aliada = Aliada.find(aliadas[row["aliadas_id"]])
    recurrence = AliadaWorkingHour.find_or_initialize_by(aliada_id: aliada.id, weekday: row["dia"].downcase, hour: row["hora"].hour, periodicity: 7, owner: 'aliada', total_hours: 1, user_id: nil)

    if recurrence.new_record?
      recurrence.save
      puts "ALIADAWORKINGHOUR #{row["id"]} #{recurrence.errors.messages.to_yaml}" if not recurrence.errors.messages.empty?
    end

  end
  
end

puts "MIGRANDO AGENDA"
agenda_errors = 0
connection.query("SELECT * FROM agenda WHERE elim = 0").each do |row|

  tz = ActiveSupport::TimeZone.new 'Mexico City'
  time_obj = tz.parse("#{row["fecha"].to_s} #{row["hora"]}")

  datetime = time_obj.to_datetime

  if datetime.minute != 0
    datetime = (datetime + 30.minute).beginning_of_hour
  end

  time_obj = datetime.utc

  #PREREQ for services
  if row["pagado"] == 1
    status_service = 'paid'
  elsif row["duracion"] 
    status_service = 'finished'
  else
    status_service = 'aliada_assigned'
  end

  if row["recurrencias_id"]
    type_service = ServiceType.find_or_create_by(name: 'recurrent')
  else
    type_service = ServiceType.find_or_create_by(name: 'one-time')
  end

  if clientes[row["clientes_id"]] and aliadas[row["aliadas_id"]]

    address = User.find(clientes[row["clientes_id"]]).addresses.first

    service = Service.find_or_initialize_by(status: status_service, aliada_id: aliadas[row["aliadas_id"]], user_id: clientes[row["clientes_id"]], bedrooms: row["recamaras"], bathrooms: row["banos"], service_type_id: type_service.id, datetime: time_obj, special_instructions: row["indicacion_instrucciones_esp"], entrance_instructions: (row["indicacion_entrada_aliada"] == "Cliente en casa"), cleaning_supplies_instructions: row["indicacion_donde_utensilios_limpieza"], garbage_instructions: row["indicacion_donde_basura"], attention_instructions: row["indicacion_especial_atencion"], equipment_instructions: row["indicacion_equipo_especial"], forbidden_instructions: row["indicacion_no_tocar"], hours_after_service: 2, address_id: address.id, zone_id: address.postal_code.zone.id) do |add|
      add.billed_hours = row["duracion"] ? row["duracion"] : 0
      add.estimated_hours = row["duracion_aprox"]
    end

    if service.new_record?
      service.save
      puts "SERVICE #{row["id"]} #{service.errors.messages.to_yaml}" if not service.errors.messages.empty?
    end

    if service.id
      servicios[row["id"]] = service.id
      aliada = Aliada.find(aliadas[row["aliadas_id"]])

      if row["recurrencias_id"]
        if not recurrence_with_service[row["recurrencias_id"]]
          recurrence_with_service[row["recurrencias_id"]] = []
        end
        recurrence_with_service[row["recurrencias_id"]] << service.id
      end

      # Creating (DURACION APROX + 2) Schedules
      ( 0..( service.estimated_hours - 1 ) ).each do |i|
        
        # si truena, sólo porque se sale de las horas de trabajo, no importa
        schedule = Schedule.find_or_initialize_by(datetime: ( time_obj + i.hour ), aliada_id: aliadas[row["aliadas_id"]], user_id: clientes[row["clientes_id"]], status: 'booked', service_id: service.id)

        if schedule.new_record?
          begin
            schedule.zones = aliada.zones
            schedule.save
          rescue => e
            agenda_errors += 1
            puts "AGENDA_KEY_ERROR #{row["id"]} ALIADA #{aliada.first_name} DATETIME #{time_obj}"
            #puts "SCHEDULE #{row["id"]} #{schedule.errors.messages.to_yaml}" if not schedule.errors.messages.empty?
          end
        end

        if row["recurrencias_id"] and schedule.id
          if not recurrence_with_schedule[row["recurrencias_id"]]
            recurrence_with_schedule[row["recurrencias_id"]] = []
          end
          recurrence_with_schedule[row["recurrencias_id"]] << schedule.id
        end

      end

    end
   
  end

end
puts "AGENDA_ERRORS #{agenda_errors}"

puts "MIGRANDO RECURRENCIAS"
connection.query("SELECT * FROM recurrencias").each do |row|
 
  if row["monday"] == 1
    weekday = "monday"
  elsif row["tuesday"] == 1
    weekday = "tuesday"
  elsif row["wednesday"] == 1
    weekday = "wednesday"
  elsif row["thursday"] == 1
    weekday = "thursday"
  elsif row["friday"] == 1
    weekday = "friday"
  elsif row["saturday"] == 1
    weekday = "saturday"
  elsif row["sunday"] == 1
    weekday = "sunday"
  else
    weekday = nil
  end

  begin
    if weekday

      recurrence = Recurrence.find_or_initialize_by(periodicity: 7, owner: 'user', weekday: weekday, hour: row["hora"].hour, total_hours: row["duracion_aprox"].ceil + 2, user_id: clientes[row["clientes_id"]], aliada_id: aliadas[row["aliadas_id"]])

      if recurrence.new_record?
        recurrence.save
        puts "RECURRENCE #{row["id"]} #{recurrence.errors.messages.to_yaml}" if not recurrence.errors.messages.empty?
      end

      #Actualizar servicios  
      if recurrence_with_service[row["id"]]
        recurrence_with_service[row["id"]].each do |service_id|
          Service.find(service_id).update_attribute(:recurrence_id, recurrence.id)
        end
      end

      #puts "SAVED RECURRENCE ID #{recurrence.id}"
      #Actualizar schedules, por el numero de total_hours
               
      ( 0..( recurrence.total_hours - 1 ) ).each do |counter|

        aliada_working_hour = AliadaWorkingHour.find_or_initialize_by(aliada_id: recurrence.aliada_id, weekday: weekday, hour: recurrence.hour + counter, periodicity: 7, owner: 'aliada', total_hours: 1)

        if aliada_working_hour.new_record? 
          aliada_working_hour.status = 'inactive'
          aliada_working_hour.save!
          #puts "INACTIVE ALIADA WORKING HOUR #{aliada_working_hour.id}"
        end

        if recurrence_with_schedule[row["id"]] 
          recurrence_with_schedule[row["id"]].each do |schedule_id|
        
            schedule = Schedule.find(schedule_id)

            #puts "TO RECURRENCE #{row["id"]} SCHEDULE #{schedule.datetime.in_time_zone("Mexico City").hour} DATETIME ALIADA WORKING HOURS #{aliada_working_hour.hour}"
            
            if schedule.datetime.hour == aliada_working_hour.utc_hour(schedule.datetime)
              schedule.update_attribute(:recurrence_id, aliada_working_hour.id)
              #puts "RECURRENCE #{row["id"]} WITH SCHEDULE ID #{schedule_id} ALIADAWORKINGHOUR ID #{aliada_working_hour.id}"
            end

          end

        end
      
      end  

    end
  rescue Exception => e
    puts "RECURRENCE_ERROR #{e}"
  end

end


puts "MIGRANDO CALIFICACIONES"
connection.query("SELECT * FROM calificaciones").each do |row|

  score = Score.find_or_create_by(user_id: clientes[row["clientes_id"]], aliada_id: aliadas[row["aliadas_id"]], comment: row["comentario"], value: row["calificacion"], service_id: servicios[row["agenda_id"]])

  if score.new_record?
    score.save
    puts "SCORE #{row["id"]} #{score.errors.messages.to_yaml}" if not score.errors.messages.empty?
  end

end

zones = nil
aliadas = nil
clientes = nil
recurrence_with_service = nil
servicios = nil

connection.close
