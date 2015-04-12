# -*- encoding : utf-8 -*-
class ChangePeriodicityType < ActiveRecord::Migration
  def up
    change_column :service_types, :periodicity, 'integer USING CAST(periodicity AS integer)'
  end

  def down
    change_column :service_types, :periodicity, :integer
  end
end
