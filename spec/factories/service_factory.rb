# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :service, class: Service do
    association :user, factory: :user
    association :aliada, factory: :aliada
    association :address, factory: :address
    association :zone, factory: :zone
    estimated_hours 3.0
    datetime Time.zone.now.in_time_zone('Mexico City').change(hour: Setting.beginning_of_aliadas_day, min: 0)
    association :service_type, factory: :service_type

    special_instructions ''
    garbage_instructions ''
    attention_instructions ''
    equipment_instructions ''
    forbidden_instructions ''
    cleaning_supplies_instructions ''

    # By defaul factory girl does Class.new()
    # we want the attributes passed to the constructor
    # so our after_initialize callbacks don't fail
    FactoryGirl.define do
      initialize_with { new(attributes) }
    end
  end
end
