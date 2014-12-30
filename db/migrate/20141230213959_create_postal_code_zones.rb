class CreatePostalCodeZones < ActiveRecord::Migration
  def change
    create_table :postal_code_zones do |t|
      t.belongs_to :postal_code, index: true
      t.belongs_to :zone, index: true

      t.timestamps null: false
    end
    add_foreign_key :postal_code_zones, :postal_codes
    add_foreign_key :postal_code_zones, :zones
  end
end
