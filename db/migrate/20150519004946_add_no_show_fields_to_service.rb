class AddNoShowFieldsToService < ActiveRecord::Migration
  def change
    add_column :services, :not_rendered_reason, :string
    add_column :services, :incident, :text
  end
end
