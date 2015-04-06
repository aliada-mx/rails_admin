class AddIndexToDatetimeUserIdInServices < ActiveRecord::Migration
  def change
    add_index "services", ["datetime", "user_id"], name: "index_services_on_datetime_and_user_id", unique: true, using: :btree
  end
end
