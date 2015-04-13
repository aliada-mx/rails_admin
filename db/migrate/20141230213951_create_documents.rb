# -*- encoding : utf-8 -*-
class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.belongs_to :user, index: true
      t.attachment :file

      t.timestamps null: false
    end
    add_foreign_key :documents, :users
  end
end
