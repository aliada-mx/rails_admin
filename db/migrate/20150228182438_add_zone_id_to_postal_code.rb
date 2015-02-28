class AddZoneIdToPostalCode < ActiveRecord::Migration
  def change
    add_column :postal_codes, :zone_id, :integer
  end
end
