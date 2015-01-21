FactoryGirl.define do
  factory :service, class: Service do
    association :address, factory: :address
    billable_hours 3.0
    status 'pending'
    time Time.zone.now.change(min: 0)
    date Time.zone.now

    before :create do |service|
      service.service_type_id = create(:service_type).id
    end
  end
end
