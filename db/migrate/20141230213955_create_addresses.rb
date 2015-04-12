# -*- encoding : utf-8 -*-
class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.belongs_to :user, index: true
      t.belongs_to :postal_code, index: true

      t.timestamps null: false
    end
    add_foreign_key :addresses, :users
    add_foreign_key :addresses, :postal_codes
  end
end
