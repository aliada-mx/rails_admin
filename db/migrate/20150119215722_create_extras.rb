class CreateExtras < ActiveRecord::Migration
  def change
    create_table :extras do |t|
      t.string :name
      t.decimal :horas, precision: 10, scale: 3

      t.timestamps null: false
    end
  end
end
