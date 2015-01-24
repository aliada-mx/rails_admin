FactoryGirl.define do
  factory :service, class: Service do
    association :user, factory: :user
    association :aliada, factory: :aliada
    association :address, factory: :address
    billable_hours 3.0
    status 'pending'
    datetime Time.zone.now.change(min: 0)
    association :service_type, factory: :service_type
  end
end
