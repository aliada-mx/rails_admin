class AddPositionToExtras < ActiveRecord::Migration
  def change
    add_column :extras, :position, :integer
  end
end
