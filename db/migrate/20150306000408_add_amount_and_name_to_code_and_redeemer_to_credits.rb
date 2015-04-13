# -*- encoding : utf-8 -*-
class AddAmountAndNameToCodeAndRedeemerToCredits < ActiveRecord::Migration
  def change
    add_column :codes, :amount, :decimal, precision: 8, scale: 4
    add_column :codes, :name, :string
    add_column :credits, :redeemer_id, :integer
  end
end
