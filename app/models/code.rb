class Code < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_type
end
