class AddBackConektaCustomerIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :conekta_customer_id, :string
  end
end
