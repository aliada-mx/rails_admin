class DropUserZonesTable < ActiveRecord::Migration
  def change
    drop_table :user_zones
  end
end
