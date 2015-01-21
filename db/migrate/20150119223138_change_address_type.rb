class ChangeAddressType < ActiveRecord::Migration
  def change
    rename_column :addresses, :address, :street

    remove_column :addresses, :municipality, :string
    add_column :addresses, :city, :string
    add_column :addresses, :references, :text
  end
end
