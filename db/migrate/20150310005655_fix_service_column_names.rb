# -*- encoding : utf-8 -*-
class FixServiceColumnNames < ActiveRecord::Migration
  def change
    rename_column :services, :begin_time, :aliada_reported_begin_time
    rename_column :services, :end_time, :aliada_reported_end_time
  end
end
