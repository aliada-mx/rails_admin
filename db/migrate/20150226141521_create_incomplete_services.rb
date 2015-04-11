# -*- encoding : utf-8 -*-
class CreateIncompleteServices < ActiveRecord::Migration
  def change
    create_table :incomplete_services do |t|
      t.belongs_to  :service
      t.string   "email",                  limit: nil
      t.string   "phone",                  limit: nil
      t.string   "first_name",             limit: nil
      t.string   "last_name",              limit: nil
      t.integer  "service_type_id"
      t.integer  "bathrooms"
      t.integer  "bedrooms"
      t.string   "date"
      t.string   "time"
      t.decimal  "estimated_hours",                            precision: 10, scale: 3
      t.text     "street"
      t.string   "number"
      t.string   "interior_number"
      t.text     "between_streets"
      t.text     "colony"
      t.string   "state",                limit: nil
      t.string   "city",                 limit: nil
      t.text     "extra_ids"
      t.integer  "map_zoom"
      t.string   "postal_code"
      t.decimal  "latitude",                         precision: 10, scale: 7
      t.decimal  "longitude",                        precision: 10, scale: 7

      t.timestamps
    end
  end
end
