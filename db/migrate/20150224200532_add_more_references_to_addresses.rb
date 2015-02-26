class AddMoreReferencesToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :map_zoom, :integer
    add_column :addresses, :references_latitude, :decimal, precision: 10, scale: 7 
    add_column :addresses, :references_longitude, :decimal, precision: 10, scale: 7
  end
end
