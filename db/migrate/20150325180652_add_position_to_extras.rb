# -*- encoding : utf-8 -*-
class AddPositionToExtras < ActiveRecord::Migration
  def change
    add_column :extras, :position, :integer
  end
end
