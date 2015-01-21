class CreateExtraServices < ActiveRecord::Migration
  def change
    create_table :extra_services do |t|
      t.integer :extra_id
      t.integer :service_id

      t.timestamps null: false
    end
  end
end
