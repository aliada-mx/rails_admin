FactoryGirl.define do
  factory :service_type, class: ServiceType do
    name 'recurrent'
    periodicity 7
  end
end
