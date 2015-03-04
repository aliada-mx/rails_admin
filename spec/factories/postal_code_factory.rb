FactoryGirl.define do
  factory :postal_code, class: PostalCode do
    sequence(:code){ |n| "#{n}#{n}#{n}#{n}#{n}" }
    association :zone, factory: :zone
  end

  trait :zoned do
    transient do
      zone { create(:zone) }
    end

    before :create do |postal_code, evaluator|
      postal_code.zone = evaluator.zone
      postal_code.save!
    end
  end
end
