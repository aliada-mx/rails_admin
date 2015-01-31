# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150130232530) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "postal_code_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.text     "street"
    t.integer  "number"
    t.integer  "interior_number"
    t.text     "between_streets"
    t.text     "colony"
    t.string   "state"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "city"
    t.text     "references"
  end

  add_index "addresses", ["postal_code_id"], name: "index_addresses_on_postal_code_id", using: :btree
  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id", using: :btree

  create_table "aliadas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "code_types", force: :cascade do |t|
    t.integer  "value"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "code_users", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "code_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "code_users", ["code_id"], name: "index_code_users_on_code_id", using: :btree
  add_index "code_users", ["user_id"], name: "index_code_users_on_user_id", using: :btree

  create_table "codes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "code_type_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "codes", ["code_type_id"], name: "index_codes_on_code_type_id", using: :btree
  add_index "codes", ["user_id"], name: "index_codes_on_user_id", using: :btree

  create_table "documents", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "documents", ["user_id"], name: "index_documents_on_user_id", using: :btree

  create_table "extra_services", force: :cascade do |t|
    t.integer  "extra_id"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "extras", force: :cascade do |t|
    t.string   "name"
    t.decimal  "hours",      precision: 10, scale: 3
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "payment_methods", force: :cascade do |t|
    t.integer  "code_type_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "name"
  end

  add_index "payment_methods", ["code_type_id"], name: "index_payment_methods_on_code_type_id", using: :btree

  create_table "payments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "payment_method_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "payments", ["payment_method_id"], name: "index_payments_on_payment_method_id", using: :btree
  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "postal_code_zones", force: :cascade do |t|
    t.integer  "postal_code_id"
    t.integer  "zone_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "postal_code_zones", ["postal_code_id"], name: "index_postal_code_zones_on_postal_code_id", using: :btree
  add_index "postal_code_zones", ["zone_id"], name: "index_postal_code_zones_on_zone_id", using: :btree

  create_table "postal_codes", force: :cascade do |t|
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recurrences", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "periodicity"
    t.integer  "aliada_id"
    t.string   "weekday"
    t.integer  "hour"
    t.integer  "total_hours"
    t.integer  "zone_id"
  end

  add_index "recurrences", ["user_id"], name: "index_recurrences_on_user_id", using: :btree

  create_table "schedules", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "status"
    t.datetime "datetime"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "aliada_id"
    t.integer  "zone_id"
  end

  add_index "schedules", ["service_id"], name: "index_schedules_on_service_id", using: :btree
  add_index "schedules", ["user_id"], name: "index_schedules_on_user_id", using: :btree

  create_table "scores", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "scores", ["user_id"], name: "index_scores_on_user_id", using: :btree

  create_table "service_types", force: :cascade do |t|
    t.string   "name"
    t.integer  "periodicity"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "price_per_hour"
    t.string   "display_name"
  end

  create_table "services", force: :cascade do |t|
    t.integer  "zone_id"
    t.integer  "address_id"
    t.integer  "user_id"
    t.integer  "service_type_id"
    t.integer  "price"
    t.integer  "recurrence_id"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.decimal  "billable_hours",       precision: 10, scale: 3
    t.decimal  "hours_before_service", precision: 10, scale: 3
    t.decimal  "hours_after_service",  precision: 10, scale: 3
    t.integer  "bathrooms"
    t.integer  "bedrooms"
    t.text     "special_instructions"
    t.string   "status"
    t.integer  "payment_method_id"
    t.integer  "aliada_id"
    t.datetime "datetime"
  end

  add_index "services", ["address_id"], name: "index_services_on_address_id", using: :btree
  add_index "services", ["recurrence_id"], name: "index_services_on_recurrence_id", using: :btree
  add_index "services", ["service_type_id"], name: "index_services_on_service_type_id", using: :btree
  add_index "services", ["user_id"], name: "index_services_on_user_id", using: :btree
  add_index "services", ["zone_id"], name: "index_services_on_zone_id", using: :btree

  create_table "table_extras_services", force: :cascade do |t|
    t.integer "extra_id"
    t.integer "service_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string   "classification"
    t.integer  "relevant_object_id"
    t.string   "relevant_object_type"
    t.text     "message"
    t.string   "action_needed"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "user_zones", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_zones", ["user_id"], name: "index_user_zones_on_user_id", using: :btree
  add_index "user_zones", ["zone_id"], name: "index_user_zones_on_zone_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "role"
    t.string   "email"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "phone"
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "authentication_token"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "zones", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "addresses", "postal_codes"
  add_foreign_key "addresses", "users"
  add_foreign_key "code_users", "codes"
  add_foreign_key "code_users", "users"
  add_foreign_key "codes", "code_types"
  add_foreign_key "codes", "users"
  add_foreign_key "documents", "users"
  add_foreign_key "payment_methods", "code_types"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "users"
  add_foreign_key "postal_code_zones", "postal_codes"
  add_foreign_key "postal_code_zones", "zones"
  add_foreign_key "recurrences", "users"
  add_foreign_key "schedules", "services"
  add_foreign_key "schedules", "users"
  add_foreign_key "scores", "users"
  add_foreign_key "services", "addresses"
  add_foreign_key "services", "recurrences"
  add_foreign_key "services", "service_types"
  add_foreign_key "services", "users"
  add_foreign_key "services", "zones"
  add_foreign_key "user_zones", "users"
  add_foreign_key "user_zones", "zones"
end
