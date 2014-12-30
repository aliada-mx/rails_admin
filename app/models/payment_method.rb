class PaymentMethod < ActiveRecord::Base
  belongs_to :code_type
end
