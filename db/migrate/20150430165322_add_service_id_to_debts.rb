class AddServiceIdToDebts < ActiveRecord::Migration
  def change
    add_column :debts, :service_id, :integer
  end
end
