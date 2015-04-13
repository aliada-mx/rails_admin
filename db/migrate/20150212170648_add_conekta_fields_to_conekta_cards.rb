# -*- encoding : utf-8 -*-
class AddConektaFieldsToConektaCards < ActiveRecord::Migration
  def change
    rename_column :conekta_cards, :exp_mont, :exp_month
    add_column :conekta_cards, :brand, :string
    add_column :conekta_cards, :name, :string
  end
end
