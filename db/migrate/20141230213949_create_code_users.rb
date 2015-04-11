# -*- encoding : utf-8 -*-
class CreateCodeUsers < ActiveRecord::Migration
  def change
    create_table :code_users do |t|
      t.belongs_to :user, index: true
      t.belongs_to :code, index: true

      t.timestamps null: false
    end
    add_foreign_key :code_users, :users
    add_foreign_key :code_users, :codes
  end
end
