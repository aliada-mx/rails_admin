# -*- encoding : utf-8 -*-
class MigrateOneTimeFromRecurrentToRecurrent < ActiveRecord::Migration
  def change
    one_time_from_recurrent_id = ServiceType.where(name: 'one-time-from-recurrent').first.id
    recurrent_id = ServiceType.recurrent.id

    Service.all.where(service_type_id: one_time_from_recurrent_id).update_all(service_type_id: recurrent_id )
  end
end
