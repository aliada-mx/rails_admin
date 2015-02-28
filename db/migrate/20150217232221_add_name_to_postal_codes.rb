class AddNameToPostalCodes < ActiveRecord::Migration
  def change
    add_column :postal_codes, :name, :string
  end
end
