class AddPreauthorizedToConektaCards < ActiveRecord::Migration
  def change
    add_column :conekta_cards, :preauthorized, :boolean
  end
end
