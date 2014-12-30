class CreateServiceTypes < ActiveRecord::Migration
  def change
    create_table :service_types do |t|
      t.string :name
      t.string :periodicity
      t.integer :price

      t.timestamps null: false
    end
  end
end
