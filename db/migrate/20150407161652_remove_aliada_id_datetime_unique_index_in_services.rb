# -*- encoding : utf-8 -*-
class RemoveAliadaIdDatetimeUniqueIndexInServices < ActiveRecord::Migration
  def change
    remove_index :services, "datetime_and_user_id"
  end
end
