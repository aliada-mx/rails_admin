# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :aliada_working_hour, class: AliadaWorkingHour do
    weekday 'monday'
    hour 7
    periodicity 7
    association :aliada, factory: :aliada
  end
end
