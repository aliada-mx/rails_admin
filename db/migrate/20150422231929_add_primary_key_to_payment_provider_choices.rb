class AddPrimaryKeyToPaymentProviderChoices < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("ALTER TABLE payment_provider_choices  ADD PRIMARY KEY (id)")
    
  end
end
