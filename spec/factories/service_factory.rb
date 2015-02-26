FactoryGirl.define do
  factory :service, class: Service do
    association :user, factory: :user
    association :aliada, factory: :aliada
    association :address, factory: :address
    association :zone, factory: :zone
    estimated_hours 3.0
    datetime Time.zone.now.change(hour: Setting.beginning_of_aliadas_day, min: 0)
    association :service_type, factory: :service_type

    # By defaul factory girl does Class.new()
    # we want the attributes passed to the constructor
    # so our after_initialize callbacks don't fail
    FactoryGirl.define do
      initialize_with { new(attributes) }
    end
  end
end
