# -*- encoding : utf-8 -*-
class AddValueAndAliadaIdToScores < ActiveRecord::Migration
  def change
    add_column :scores, :value, :decimal, precision: 5, scale: 2
    add_column :scores, :aliada_id, :integer
  end
end
