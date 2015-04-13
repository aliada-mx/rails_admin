# -*- encoding : utf-8 -*-
class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.belongs_to :user, index: true
      t.belongs_to :payment_method, index: true

      t.timestamps null: false
    end
    add_foreign_key :payments, :users
    add_foreign_key :payments, :payment_methods
  end
end
