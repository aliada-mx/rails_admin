# -*- encoding : utf-8 -*-
class CreatePostalCodes < ActiveRecord::Migration
  def change
    create_table :postal_codes do |t|
      t.string :code

      t.timestamps null: false
    end
  end
end
