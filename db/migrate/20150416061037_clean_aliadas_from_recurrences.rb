class CleanAliadasFromRecurrences < ActiveRecord::Migration
  def change
    Recurrence.all.each do |awh|
      awh.destroy if awh.owner == 'aliada'
    end
  end
end
