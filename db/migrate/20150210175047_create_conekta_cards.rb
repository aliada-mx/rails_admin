# -*- encoding : utf-8 -*-
class CreateConektaCards < ActiveRecord::Migration
  def change
    create_table :conekta_cards do |t|
      t.string :token
      t.string :last4
      t.string :exp_mont
      t.string :exp_year
      t.boolean :active

      t.timestamps
    end
  end
end
