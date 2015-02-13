class CreateJoinTablePaymentMethodUser < ActiveRecord::Migration
  def change
    create_join_table :PaymentMethods, :Users, table_name: :payment_choices do |t|
      t.integer :payment_method_id
      t.integer :payment_method_type

      t.integer :user_id
      t.boolean :default
      # t.index [:payment_method_id, :user_id]
      # t.index [:user_id, :payment_method_id]
    end
  end
end
