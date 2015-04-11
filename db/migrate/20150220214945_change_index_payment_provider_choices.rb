# -*- encoding : utf-8 -*-
class ChangeIndexPaymentProviderChoices < ActiveRecord::Migration
  def change
    remove_index "payment_provider_choices", name: "index_payment_provider_choices_on_user_id_and_default"
    add_index "payment_provider_choices", ["user_id", "default"], name: "index_payment_provider_choices_on_user_id_and_default", unique: true,  where: "payment_provider_choices.default = true", using: :btree
  end
end
