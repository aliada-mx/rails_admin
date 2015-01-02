class AddFieldsToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :address,         :text
    add_column :addresses, :number,          :integer
    add_column :addresses, :interior_number, :integer
    add_column :addresses, :between_streets, :text
    add_column :addresses, :colony,          :text
    add_column :addresses, :state,           :string
    add_column :addresses, :municipality,    :text
    add_column :addresses, :postal_code,     :string
    add_column :addresses, :latitude,        :float, {precision: 10, scale: 6}
    add_column :addresses, :longitude,       :float, {precision: 10, scale: 6}
  end
end
