class AddHiddenToServiceTypes < ActiveRecord::Migration
  def change
    add_column :service_types, :hidden, :boolean, default: false
  end
end
