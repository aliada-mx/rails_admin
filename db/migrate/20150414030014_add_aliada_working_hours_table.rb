# -*- encoding : utf-8 -*-
class AddAliadaWorkingHoursTable < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute("CREATE TABLE aliada_working_hours AS SELECT * FROM recurrences;")
    ActiveRecord::Base.connection.execute("ALTER TABLE aliada_working_hours ADD PRIMARY KEY (id)")

    add_foreign_key :recurrences, :users
  end

  def down
    drop_table :aliada_working_hours
  end
end
