# -*- encoding : utf-8 -*-
class AddAliadaIdToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :aliada_id, :integer
  end
end
