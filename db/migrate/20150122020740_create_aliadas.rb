# -*- encoding : utf-8 -*-
class CreateAliadas < ActiveRecord::Migration
  def change
    create_table :aliadas do |t|

      t.timestamps null: false
    end
  end
end
