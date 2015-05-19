# -*- encoding : utf-8 -*-
class MigrateOneTimeFromRecurrentToRecurrent < ActiveRecord::Migration
  def change
    Service.all.where(service_type_id: 3).update_all(service_type_id: 1)

    ServiceType.find_by(name: 'one-time-from-recurrent').destroy
  end
end
