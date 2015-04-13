# -*- encoding : utf-8 -*-
class AddServiceConfirmation < ActiveRecord::Migration
  def change
    add_column :services, :confirmed, :boolean, default: false
  end
end
