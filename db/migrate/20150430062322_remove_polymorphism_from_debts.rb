class RemovePolymorphismFromDebts < ActiveRecord::Migration
  def change
    remove_column :debts, :payeable_type
    remove_column :debts, :payeable_id
  end
end
