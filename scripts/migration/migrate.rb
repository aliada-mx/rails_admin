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

connection.query("SELECT * FROM zonas WHERE elim = 0").each do |row|
  zone = Zone.find_or_create_by(name: row["nombre"])
  zones[row["id"]] = zone.id
end

connection.query("SELECT * FROM cp WHERE elim = 0").each do |row|
  cp = PostalCode.find_or_create_by(code: row["cp"], name: row["nombre"])
  pcz = PostalCodeZone.find_or_create_by(postal_code_id: cp.id, zone_id: zones[row["zonas_id"]])
end

connection.query("SELECT * FROM aliadas WHERE elim = 0").each do |row|
  row["email"] = "inventado_#{row["id"]}@aliada.com" if row["email"].length == 0
  aliada = Aliada.find_or_create_by(first_name: row["nombres"], last_name: row["apellidos"], email: row["email"].downcase, role: "aliada", phone: row["telefono"], created_at: row["created"])
  aliadas[row["id"]] = aliada.id
end

connection.query("SELECT * FROM aliadas_has_zonas").each do |row|
  aliada = Aliada.find(aliadas[row["aliadas_id"]]) if aliadas[row["aliadas_id"]]
  aliada.zones.push(Zone.find(zones[row["zonas_id"]])) if (aliada and not aliada.zones.index(Zone.find(zones[row["zonas_id"]])))
end

connection.query("SELECT * FROM clientes WHERE estatus = 'normal'").each do |row|
  
  first_name = ""
  last_name = ""
  if row["nombre"]
    splitted_name = row["nombre"].split
    first_name = splitted_name[0] 
    last_name = splitted_name[1..splitted_name.length].join(" ") if splitted_name.length > 0
  end
  cliente = User.find_or_create_by(first_name: first_name, last_name: last_name, email: row["email"].downcase, role: "client", phone: row["telefono"], created_at: row["created"], credits: row["saldo"] )
  clientes[row["id"]] = cliente.id
end

connection.query("SELECT * FROM (SELECT * FROM clientes_has_direcciones WHERE elim = 0 ORDER BY modified DESC) t GROUP BY t.clientes_id").each do |row|
  
  cp = PostalCode.find_or_create_by(code: row["cp"])
  address = Address.find_or_create_by(user_id: clientes[row["clientes_id"]], street: row["direccion"], number: row["numero"], interior_number: row["numero_int"], between_streets: row["entre_calles"], colony: row["colonia"], state: row["estado"], city: row["delegacion"], postal_code_id: cp.id,  references: row["referencia"]) do |add|
    #treated separately, because decimal objects are different for find_or_create and were duplicating objects
    add.latitude = row["latitud"]
    add.longitude = row["longitud"]
  end

end

connection.query("SELECT * FROM metodospagos ORDER BY created DESC").each do |row|

  if (clientes[row["clientes_id"]])
    cliente = User.find(clientes[row["clientes_id"]])
    conektaCard = ConektaCard.find_or_create_by(token: row["TOKEN"], last4: 'XXXX', exp_month: '00', exp_year: '00', active: true, preauthorized: true, customer_id: row["CLIENT_ID"], brand: 'other', name: "#{cliente.first_name} #{cliente.last_name}" )
    if cliente.payment_provider_choices.empty? 
      paymentProviderChoice = PaymentProviderChoice.find_or_create_by(user_id: cliente.id, payment_provider_id: conektaCard.id, payment_provider_type: "ConektaCard", default: true)
    else
      paymentProviderChoice = PaymentProviderChoice.find_or_create_by(user_id: cliente.id, payment_provider_id: conektaCard.id, payment_provider_type: "ConektaCard", default: false)
    end
  end

end

connection.query("SELECT * FROM horarios").each do |row|
  
  if (aliadas[row["aliadas_id"]])
    recurrence = Recurrence.find_or_create_by(aliada_id: aliadas[row["aliadas_id"]], weekday: row["dia"].downcase, hour: row["hora"].hour, periodicity: 7, owner: 'aliada', total_hours: 1)
  end
  
end

connection.query("SELECT * FROM agenda WHERE elim = 0").each do |row|
 
  datetime = row["fecha"].in_time_zone + row["hora"].hour.hour
  schedule = Schedule.find_or_create_by(datetime: datetime, aliada_id: aliadas[row["aliadas_id"]], user_id: clientes[row["clientes_id"]])


#t.integer  "user_id"
#    t.string   "status"
#    t.datetime "datetime"
#    t.integer  "service_id"
#    t.datetime "created_at", null: false
#    t.datetime "updated_at", null: false
#    t.integer  "aliada_id"
#    t.integer  "zone_id"

 
  #SERVICE - BILLABLE HOURS
  #, billed_hours: row["duracion"], estimated_hours: row["duracion_aprox"]

  #old.agenda.pagado 
  #old.agenda.TOKEN   se repite en recurrencias -> crear y pasar a 'conekta_create_card', que no existe
  #old.agenda.METODO

  #old.agenda.recamaras -> new.services.bedrooms
  #old.agenda.banos -> new.services.bathrooms
  #old.agenda.incluir_productos_limpieza + old.agenda.indicacion_entrada_aliada + old.agenda.indicacion_donde_utensilios_limpieza + old.agenda.indicacion_donde_basura + old.agenda.indicacion_especial_atencion + old.agenda.indicacion_equipo_especial + old.agenda.indicacion_no_tocar + old.agenda.indicacion_instrucciones_esp *-> new.services.special_instructions

  #old.agenda.recurrencias_id *-> new.services.recurrence_id
  #old.agenda.elim -> ?



end

#connection.query("SELECT * FROM calificaciones").each do |row|

#  score = Score.find_or_create_by(user_id: clientes[row["clientes_id"]], aliada_id: aliadas[row["aliadas_id"]], comment: row["comentario"], value: row["calificacion"])

#end

zones = nil
aliadas = nil
clientes = nil

connection.close
