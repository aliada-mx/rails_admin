# -*- encoding : utf-8 -*-
class CreateAliadaZones < ActiveRecord::Migration
  def change
    create_table :aliada_zones do |t|
      t.integer :aliada_id
      t.integer :zone_id

      t.timestamps
    end
  end
end
