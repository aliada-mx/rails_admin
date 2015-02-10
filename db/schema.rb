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

ActiveRecord::Schema.define(version: 20150205221633) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: true do |t|
    t.integer  "user_id"
    t.integer  "postal_code_id"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.text     "street"
    t.integer  "number"
    t.integer  "interior_number"
    t.text     "between_streets"
    t.text     "colony"
    t.string   "state",           limit: nil
    t.string   "city",            limit: nil
    t.text     "references"
    t.decimal  "latitude",                    precision: 10, scale: 7
    t.decimal  "longitude",                   precision: 10, scale: 7
  end

  add_index "addresses", ["postal_code_id"], name: "index_addresses_on_postal_code_id", using: :btree
  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id", using: :btree

  create_table "aliada_zones", force: true do |t|
    t.integer  "aliada_id"
    t.integer  "zone_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "banned_aliada_users", force: true do |t|
    t.integer  "aliada_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "code_types", force: true do |t|
    t.integer  "value"
    t.string   "name",       limit: nil
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "code_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "code_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "code_users", ["code_id"], name: "index_code_users_on_code_id", using: :btree
  add_index "code_users", ["user_id"], name: "index_code_users_on_user_id", using: :btree

  create_table "codes", force: true do |t|
    t.integer  "user_id"
    t.integer  "code_type_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "codes", ["code_type_id"], name: "index_codes_on_code_type_id", using: :btree
  add_index "codes", ["user_id"], name: "index_codes_on_user_id", using: :btree

  create_table "documents", force: true do |t|
    t.integer  "user_id"
    t.string   "file_file_name",    limit: nil
    t.string   "file_content_type", limit: nil
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "documents", ["user_id"], name: "index_documents_on_user_id", using: :btree

  create_table "extra_services", force: true do |t|
    t.integer  "extra_id"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "extras", force: true do |t|
    t.string   "name",       limit: nil
    t.decimal  "hours",                  precision: 10, scale: 3
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  create_table "payment_methods", force: true do |t|
    t.integer  "code_type_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "name",         limit: nil
  end

  add_index "payment_methods", ["code_type_id"], name: "index_payment_methods_on_code_type_id", using: :btree

  create_table "payments", force: true do |t|
    t.integer  "user_id"
    t.integer  "payment_method_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "payments", ["payment_method_id"], name: "index_payments_on_payment_method_id", using: :btree
  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "postal_code_zones", force: true do |t|
    t.integer  "postal_code_id"
    t.integer  "zone_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "postal_code_zones", ["postal_code_id"], name: "index_postal_code_zones_on_postal_code_id", using: :btree
  add_index "postal_code_zones", ["zone_id"], name: "index_postal_code_zones_on_zone_id", using: :btree

  create_table "postal_codes", force: true do |t|
    t.string   "code",       limit: nil
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "recurrences", force: true do |t|
    t.integer  "user_id"
    t.string   "status",      limit: nil
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "periodicity"
    t.integer  "aliada_id"
    t.string   "weekday",     limit: nil
    t.integer  "hour"
    t.integer  "total_hours"
    t.integer  "zone_id"
  end

  add_index "recurrences", ["user_id"], name: "index_recurrences_on_user_id", using: :btree

  create_table "schedules", force: true do |t|
    t.integer  "user_id"
    t.string   "status",     limit: nil
    t.datetime "datetime"
    t.integer  "service_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "aliada_id"
    t.integer  "zone_id"
  end

  add_index "schedules", ["service_id"], name: "index_schedules_on_service_id", using: :btree
  add_index "schedules", ["user_id"], name: "index_schedules_on_user_id", using: :btree

  create_table "scores", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.decimal  "value",      precision: 5, scale: 2
    t.integer  "aliada_id"
  end

  add_index "scores", ["user_id"], name: "index_scores_on_user_id", using: :btree

  create_table "service_types", force: true do |t|
    t.string   "name",           limit: nil
    t.integer  "periodicity"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "price_per_hour"
    t.string   "display_name",   limit: nil
  end

  create_table "services", force: true do |t|
    t.integer  "zone_id"
    t.integer  "address_id"
    t.integer  "user_id"
    t.integer  "service_type_id"
    t.integer  "price"
    t.integer  "recurrence_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.decimal  "billable_hours",                   precision: 10, scale: 3
    t.decimal  "hours_before_service",             precision: 10, scale: 3
    t.decimal  "hours_after_service",              precision: 10, scale: 3
    t.integer  "bathrooms"
    t.integer  "bedrooms"
    t.text     "special_instructions"
    t.string   "status",               limit: nil
    t.integer  "payment_method_id"
    t.integer  "aliada_id"
    t.datetime "datetime"
  end

  add_index "services", ["address_id"], name: "index_services_on_address_id", using: :btree
  add_index "services", ["recurrence_id"], name: "index_services_on_recurrence_id", using: :btree
  add_index "services", ["service_type_id"], name: "index_services_on_service_type_id", using: :btree
  add_index "services", ["user_id"], name: "index_services_on_user_id", using: :btree
  add_index "services", ["zone_id"], name: "index_services_on_zone_id", using: :btree

  create_table "table_extras_services", force: true do |t|
    t.integer "extra_id"
    t.integer "service_id"
  end

  create_table "tickets", force: true do |t|
    t.string   "classification",       limit: nil
    t.integer  "relevant_object_id"
    t.string   "relevant_object_type", limit: nil
    t.text     "message"
    t.string   "action_needed",        limit: nil
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "users", force: true do |t|
    t.string   "role",                   limit: nil
    t.string   "email",                  limit: nil
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "phone",                  limit: nil
    t.string   "encrypted_password",     limit: nil, default: "", null: false
    t.string   "reset_password_token",   limit: nil
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "first_name",             limit: nil
    t.string   "last_name",              limit: nil
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "zones", force: true do |t|
    t.string   "name",       limit: nil
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  Foreigner.load
  add_foreign_key "addresses", "postal_codes", name: "fk_rails_176653fe2c"
  add_foreign_key "addresses", "users", name: "fk_rails_adf64c847b"

  add_foreign_key "code_users", "codes", name: "fk_rails_f59cb87f20"
  add_foreign_key "code_users", "users", name: "fk_rails_a2fdb26281"

  add_foreign_key "codes", "code_types", name: "fk_rails_5766f8bb3a"
  add_foreign_key "codes", "users", name: "fk_rails_0cc1e79270"

  add_foreign_key "documents", "users", name: "fk_rails_8492e5f484"

  add_foreign_key "payment_methods", "code_types", name: "fk_rails_a96fea7b5a"

  add_foreign_key "payments", "payment_methods", name: "fk_rails_bce7901cda"
  add_foreign_key "payments", "users", name: "fk_rails_dda9bb2cf6"

  add_foreign_key "postal_code_zones", "postal_codes", name: "fk_rails_42b87c0f50"
  add_foreign_key "postal_code_zones", "zones", name: "fk_rails_0b1be18d68"

  add_foreign_key "recurrences", "users", name: "fk_rails_6e1c955ffb"

  add_foreign_key "schedules", "services", name: "fk_rails_c759b2308c"
  add_foreign_key "schedules", "users", name: "fk_rails_46c762044c"

  add_foreign_key "scores", "users", name: "fk_rails_a7985791f0"

  add_foreign_key "services", "addresses", name: "fk_rails_da43fb23af"
  add_foreign_key "services", "recurrences", name: "fk_rails_b54eadb930"
  add_foreign_key "services", "service_types", name: "fk_rails_b3316839df"
  add_foreign_key "services", "users", name: "fk_rails_098372802b"
  add_foreign_key "services", "zones", name: "fk_rails_6a9baffb04"

end
