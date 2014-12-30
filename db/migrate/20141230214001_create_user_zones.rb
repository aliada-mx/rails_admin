class CreateUserZones < ActiveRecord::Migration
  def change
    create_table :user_zones do |t|
      t.belongs_to :user, index: true
      t.belongs_to :zone, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_zones, :users
    add_foreign_key :user_zones, :zones
  end
end
