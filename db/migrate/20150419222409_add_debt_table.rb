class AddDebtTable < ActiveRecord::Migration
  def change
    create_table :debts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :payment_method, index: true
      t.timestamps null: false
      t.decimal :amount, precision: 8, scale: 4
      t.string :status
      t.references :payeable, polymorphic: true, index: true
    end
    
    add_foreign_key :debts, :users
    add_foreign_key :debts, :payment_methods
  end
end
