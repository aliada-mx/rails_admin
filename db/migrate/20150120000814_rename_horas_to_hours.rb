# -*- encoding : utf-8 -*-
class RenameHorasToHours < ActiveRecord::Migration
  def change
    rename_column :extras, :horas, :hours
  end
end
