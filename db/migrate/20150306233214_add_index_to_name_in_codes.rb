# -*- encoding : utf-8 -*-
class AddIndexToNameInCodes < ActiveRecord::Migration
  def change
    add_index "codes", "name", name: "index_codes_on_name", unique: true, using: :btree
  end
end
