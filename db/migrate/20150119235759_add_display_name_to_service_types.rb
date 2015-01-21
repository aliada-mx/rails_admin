class AddDisplayNameToServiceTypes < ActiveRecord::Migration
  def change
    add_column :service_types, :display_name, :string
  end
end
