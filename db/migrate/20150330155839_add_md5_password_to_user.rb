class AddMd5PasswordToUser < ActiveRecord::Migration
  def change
    add_column :users, :md5_password, :string
  end
end
