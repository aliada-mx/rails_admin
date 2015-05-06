class ChangePaymentsToHavePolymorphicObject < ActiveRecord::Migration
  def change
    change_table :payments do |t|
      t.references :payeable, polymorphic: true, index: true
    end    
  end
end
