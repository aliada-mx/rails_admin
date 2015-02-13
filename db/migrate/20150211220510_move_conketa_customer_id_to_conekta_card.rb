class MoveConketaCustomerIdToConektaCard < ActiveRecord::Migration
  def change
    remove_column :users, :conekta_customer_id, :string
    add_column :conekta_cards, :customer_id, :string
  end
end
