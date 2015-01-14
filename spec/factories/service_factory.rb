FactoryGirl.define do
  factory :service, class: Service do
    association :address, factory: :address
    billable_hours 3.0
    status 'pending'

    before :create do |service|
      service.service_type_id = create(:service_type).id
    end
  end
end
