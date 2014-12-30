class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.belongs_to :zone, index: true
      t.belongs_to :address, index: true
      t.belongs_to :user, index: true
      t.belongs_to :service_type, index: true
      t.integer :price
      t.belongs_to :recurrence, index: true

      t.timestamps null: false
    end
    add_foreign_key :services, :zones
    add_foreign_key :services, :addresses
    add_foreign_key :services, :users
    add_foreign_key :services, :service_types
    add_foreign_key :services, :recurrences
  end
end
