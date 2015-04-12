# -*- encoding : utf-8 -*-
class RenamePostalCodeInIncompleteServices < ActiveRecord::Migration
  def change
    rename_column :incomplete_services, :postal_code, :postal_code_number
  end
end
