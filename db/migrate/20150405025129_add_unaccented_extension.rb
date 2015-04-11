# -*- encoding : utf-8 -*-
class AddUnaccentedExtension < ActiveRecord::Migration
  def up
    execute "create extension unaccent;"
  end

  def down
    execute "drop extension unaccent;"
  end
end
