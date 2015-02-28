class AddPostalCodeNotFoundToIncompleteServices < ActiveRecord::Migration
  def change
    add_column :incomplete_services, :postal_code_not_found, :boolean
  end
end
