FactoryGirl.define do
  factory :postal_code, class: PostalCode do
    sequence(:code){ |n| "#{n}#{n}#{n}#{n}#{n}" }
  end

  trait :zoned do
    transient do
      zone { create(:zone) }
    end

    after :create do |postal_code, evaluator|
      PostalCodeZone.create(postal_code: postal_code, zone: evaluator.zone)
    end
  end
end
