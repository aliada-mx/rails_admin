# -*- encoding : utf-8 -*-
class CreateBannedAliadaUsers < ActiveRecord::Migration
  def change
    create_table :banned_aliada_users do |t|
      t.integer :aliada_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
