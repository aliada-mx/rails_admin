#!/usr/bin/env ruby
require_relative "../../config/environment"
require 'mysql2' 

client = Mysql2::Client.new(
  host: ENV["MYSQL_HOST"],
  username: ENV["MYSQL_USER"],
  password: ENV["MYSQL_PASS"],
  database: ENV["MYSQL_DB"],
)

zones = {}
aliadas = {}
clientes = {}

client.query("SELECT * FROM zonas WHERE elim = 0").each do |row|
  zone = Zone.find_or_create_by(name: row["nombre"])
  zones[row["id"]] = zone.id
end

client.query("SELECT * FROM cp WHERE elim = 0").each do |row|
  cp = PostalCode.find_or_create_by(code: row["cp"], name: row["nombre"])
  pcz = PostalCodeZone.find_or_create_by(postal_code_id: cp.id, zone_id: zones[row["zonas_id"]])
end

client.query("SELECT * FROM aliadas WHERE elim = 0").each do |row|
  row["email"] = "inventado_#{row["id"]}@aliada.com" if row["email"].length == 0
  aliada = Aliada.find_or_create_by(first_name: row["nombres"], last_name: row["apellidos"], email: row["email"], role: "aliada", phone: row["telefono"], encrypted_password: row["password"], created_at: row["created"])
  aliadas[row["id"]] = aliada.id
end

client.query("SELECT * FROM aliadas_has_zonas").each do |row|
  aliada = Aliada.find(aliadas[row["aliadas_id"]]) if aliadas[row["aliadas_id"]]
  aliada.zones.push(Zone.find(zones[row["zonas_id"]])) if (aliada and not aliada.zones.index(Zone.find(zones[row["zonas_id"]])))
end

client.query("SELECT * FROM clientes WHERE estatus = 'normal'").each do |row|
  
  cliente = User.find_or_create_by(last_name: row["nombre"], email: row["email"], role: "client", phone: row["telefono"], encrypted_password: row["password"], created_at: row["created"], credits: row["saldo"] )
  clientes[row["id"]] = cliente.id
end


#client.query("SELECT * FROM calificaciones").each do |row|

#  score = Score.find_or_create_by(user_id: clientes[row["clientes_id"]], aliada_id: aliadas[row["aliadas_id"]], comment: row["comentario"], value: row["calificacion"])

#end

zones = nil
aliadas = nil
clientes = nil

client.close
