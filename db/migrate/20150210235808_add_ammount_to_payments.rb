class AddAmmountToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :amount, :decimal, precision: 8, scale: 4
    add_column :payments, :status, :string
    add_column :payments, :api_raw_response, :text
  end
end
