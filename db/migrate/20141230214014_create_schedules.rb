class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.belongs_to :zone, index: true
      t.belongs_to :user, index: true
      t.string :status
      t.datetime :datetime
      t.belongs_to :service, index: true

      t.timestamps null: false
    end
    add_foreign_key :schedules, :zones
    add_foreign_key :schedules, :users
    add_foreign_key :schedules, :services
  end
end
