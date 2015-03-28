class AddCancelationFeeChargedToService < ActiveRecord::Migration
  def change
    add_column :services, :cancelation_fee_charged, :boolean
  end
end
