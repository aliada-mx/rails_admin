FactoryGirl.define do
  factory :service, class: Service do
    association :user, factory: :user
    association :aliada, factory: :aliada
    association :address, factory: :address
    association :zone, factory: :zone
    billable_hours 3.0
    datetime Time.zone.now.change(hour: Setting.beginning_of_aliadas_day, min: 0)
    association :service_type, factory: :service_type
  end
end
