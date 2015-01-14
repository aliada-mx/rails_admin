class ServiceType < ActiveRecord::Base
  NAMES = [
    ['recurrent','Recurrente'],
    ['one-time','Una sola vez'],
  ]

  validates :name, inclusion: {in: NAMES.map{ |pairs| pairs[0] } }
end
