class AddUserRefToPayments < ActiveRecord::Migration
  def change
    add_reference :payments, :user, index: true
  end
end
