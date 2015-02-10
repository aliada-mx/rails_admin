FactoryGirl.define do
  factory :postal_code, class: PostalCode do
    sequence(:code){ |n| "#{n}#{n}#{n}#{n}#{n}" }
  end

  trait :zoned do
    transient do
      zone { create(:zone) }
    end

    after :create do |postal_code, evaluator|
      postal_code.zones << evaluator.zone
    end
  end
end
