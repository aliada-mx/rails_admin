class AddIconToExtras < ActiveRecord::Migration
  def self.up
    add_attachment :extras, :icon
  end

  def self.down
    remove_attachment :extras, :icon
  end
end
