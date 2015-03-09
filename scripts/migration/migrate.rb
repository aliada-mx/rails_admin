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
    zone_id = nil
    if not aliada.zones.empty?
      zone_id = aliada.zones.first.id
    end
    recurrence = Recurrence.find_or_initialize_by(aliada_id: aliada.id, weekday: row["dia"].downcase, hour: row["hora"].hour, periodicity: 7, owner: 'aliada', total_hours: 1, status: nil, user_id: nil, zone_id: zone_id)

    if recurrence.new_record?
      recurrence.save
      puts "RECURRENCE #{row["id"]} #{recurrence.errors.messages.to_yaml}" if not recurrence.errors.messages.empty?
    end

  end
  
end

puts "MIGRANDO AGENDA"
connection.query("SELECT * FROM agenda WHERE elim = 0").each do |row|

  tz = ActiveSupport::TimeZone.new 'Mexico City'
  datetime = tz.parse("#{row["fecha"].to_s} #{row["hora"]}").to_datetime

  if datetime.minute != 0
    datetime = datetime - 30.minute
  end

  #PREREQ for services
  if row["pagado"] == 1
    status_service = 'paid'
  elsif row["duracion"] 
    status_service = 'finished'
  else
    status_service = 'created'
  end

  if row["recurrencias_id"]
    type_service = ServiceType.find_or_create_by(name: 'recurrent')
  else
    type_service = ServiceType.find_or_create_by(name: 'one-time')
  end

  if clientes[row["clientes_id"]] and aliadas[row["aliadas_id"]]

    address = User.find(clientes[row["clientes_id"]]).addresses.first

    service = Service.find_or_initialize_by(status: status_service, aliada_id: aliadas[row["aliadas_id"]], user_id: clientes[row["clientes_id"]], bedrooms: row["recamaras"], bathrooms: row["banos"], service_type_id: type_service.id, datetime: datetime, special_instructions: row["indicacion_instrucciones_esp"], entrance_instructions: (row["indicacion_entrada_aliada"] == "Cliente en casa"), cleaning_supplies_instructions: row["indicacion_donde_utensilios_limpieza"], garbage_instructions: row["indicacion_donde_basura"], attention_instructions: row["indicacion_especial_atencion"], equipment_instructions: row["indicacion_equipo_especial"], forbidden_instructions: row["indicacion_no_tocar"], hours_before_service: 1, hours_after_service: 1, address_id: address.id, zone_id: address.postal_code.zone.id) do |add|
      add.billed_hours = row["duracion"] ? row["duracion"] : 0
      add.estimated_hours = row["duracion_aprox"]
    end

    if service.new_record?
      service.save
      puts "SERVICE #{row["id"]} #{service.errors.messages.to_yaml}" if not service.errors.messages.empty?
    end

    if service.id
      servicios[row["id"]] = service.id

      schedule = Schedule.find_or_initialize_by(datetime: datetime, aliada_id: aliadas[row["aliadas_id"]], user_id: clientes[row["clientes_id"]], status: 'booked', service_id: service.id, zone_id: address.postal_code.zone.id)

      if schedule.new_record?
        schedule.save
        puts "SCHEDULE #{row["id"]} #{schedule.errors.messages.to_yaml}" if not schedule.errors.messages.empty?
      end

      if row["recurrencias_id"]
        if not recurrence_with_service[row["recurrencias_id"]]
          recurrence_with_service[row["recurrencias_id"]] = []
        end
        recurrence_with_service[row["recurrencias_id"]] << service.id
      end

    end
   
  end

end

puts "MIGRANDO AGENDA"
connection.query("SELECT * FROM recurrencias").each do |row|

  zone = nil
  if row["cp"] != ""
    cp = PostalCode.find_or_create_by(number: row["cp"].to_s.rjust(5, '0')) # only migrating the first zone associated to the postal_code
    zone = cp.zone.id
  end
 
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
    weekday = ""
  end

  # hour = hour - 1 | total hours = duracion aprox + 2
  recurrence = Recurrence.find_or_initialize_by(periodicity: 7, owner: 'user', weekday: weekday, hour: row["hora"].hour - 1, total_hours: row["duracion_aprox"] + 2, user_id: clientes[row["clientes_id"]], aliada_id: aliadas[row["aliadas_id"]], status: nil, zone_id: zone)

  if recurrence.new_record?
    recurrence.save
    puts "RECURRENCE #{row["id"]} #{recurrence.errors.messages.to_yaml}" if not recurrence.errors.messages.empty?
  end

  #Actualizar servicios  
  if recurrence_with_service[row["id"]]
    recurrence_with_service[row["id"]].each do |id|
      Service.find(id).update_attribute(:recurrence_id, recurrence.id)
    end
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
