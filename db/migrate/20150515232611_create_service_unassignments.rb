class CreateServiceUnassignments < ActiveRecord::Migration
  def change
    create_table :service_unassignments do |t|
      t.integer :aliada_id
      t.integer :service_id

      t.timestamps
    end
  end
end
