# -*- encoding : utf-8 -*-
class CreateCodeTypes < ActiveRecord::Migration
  def change
    create_table :code_types do |t|
      t.integer :value
      t.string :name

      t.timestamps null: false
    end
  end
end
