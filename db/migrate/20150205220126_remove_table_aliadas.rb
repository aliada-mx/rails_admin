# -*- encoding : utf-8 -*-
class RemoveTableAliadas < ActiveRecord::Migration
  def change
    drop_table :aliadas
  end
end
