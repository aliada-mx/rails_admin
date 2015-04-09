class AddFullNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :full_name, :string
  end

  def data
    User.all.map(&:save)
    Aliada.all.map(&:save)
  end
end
