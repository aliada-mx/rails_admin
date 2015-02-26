class AddIconToExtras < ActiveRecord::Migration
  def up
    add_attachment :extras, :icon, :attachment
  end

  def down
    remove_attachment :extras, :icon, :attachment
  end
end
