class AddServiceIdToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :service_id, :integer
  end
end
