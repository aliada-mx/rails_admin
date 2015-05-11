class CreatePaypalIpns < ActiveRecord::Migration
  def change
    create_table :paypal_ipns do |t|
      t.text :api_raw_response
      t.timestamps
    end
  end
end
