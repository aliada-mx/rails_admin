class AddSequenceToPaymentProviderChoiceId < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("ALTER TABLE payment_provider_choices ALTER COLUMN id SET DEFAULT nextval('payment_provider_choices_id_seq ');")
  end
end
