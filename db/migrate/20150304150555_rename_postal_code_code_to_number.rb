class RenamePostalCodeCodeToNumber < ActiveRecord::Migration
  def change
    rename_column :postal_codes, :code, :number
  end
end
