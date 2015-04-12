# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :incomplete_service, class: IncompleteService do
    email 'test@factory.com'
  end
end
