class CreateCodes < ActiveRecord::Migration
  def change
    create_table :codes do |t|
      t.belongs_to :user, index: true
      t.belongs_to :code_type, index: true

      t.timestamps null: false
    end
    add_foreign_key :codes, :users
    add_foreign_key :codes, :code_types
  end
end
