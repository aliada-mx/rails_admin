class AddUniquenessToDefaultPaymentChoice < ActiveRecord::Migration
  def change
    add_index :payment_choices, [:user_id, :default], unique: true
  end
end
