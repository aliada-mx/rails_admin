class AddIdToPaymentProviderChoices < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("CREATE SEQUENCE payment_provider_choices_id_seq;")
    ActiveRecord::Base.connection.execute("ALTER TABLE payment_provider_choices ADD id INT UNIQUE;")
    ActiveRecord::Base.connection.execute("UPDATE payment_provider_choices  SET id = NEXTVAL('payment_provider_choices_id_seq');")
  end
end
