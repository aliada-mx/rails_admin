# -*- encoding : utf-8 -*-
class CreatePaymentMethods < ActiveRecord::Migration
  def change
    create_table :payment_methods do |t|
      t.belongs_to :code_type, index: true

      t.timestamps null: false
    end
    add_foreign_key :payment_methods, :code_types
  end
end
