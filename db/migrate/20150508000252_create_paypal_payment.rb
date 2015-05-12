class CreatePaypalPayment < ActiveRecord::Migration
  def change
    create_table :paypal_charges do |t|
      t.string 'ack'
      t.decimal 'amount', precision: 10, scale: 3
      t.decimal 'fee', precision: 10, scale: 3
      t.datetime 'order_time' 
      t.string 'payment_status'
      t.string 'payment_type'
      t.string 'receipt_id'
      t.string 'transaction_id'
      t.string 'transaction_type'
      t.integer 'user_id'
      t.string 'payable_type'
      t.integer 'payable_id'
      t.text 'api_raw_response'
    end
  end
end
