class AddIdSequenceToAliadaWorkingHour < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("CREATE SEQUENCE aliada_working_hours_id_seq;")
    ActiveRecord::Base.connection.execute("ALTER TABLE aliada_working_hours ALTER id SET DEFAULT NEXTVAL('aliada_working_hours_id_seq');")
    ActiveRecord::Base.connection.execute("SELECT setval('aliada_working_hours_id_seq',(SELECT GREATEST(MAX(id)+1,nextval('aliada_working_hours_id_seq'))-1 FROM aliada_working_hours ))")
  end
end
