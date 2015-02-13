class AssociatePaymentsWithChoice < ActiveRecord::Migration
  def change
    remove_column :payments, :user_id, :integer
    remove_column :payments, :payment_method_id, :integer
    add_column :payments, :payment_choice_id, :integer
  end
end
