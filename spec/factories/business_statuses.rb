# spec/factories/business_statuses.rb
FactoryBot.define do
  factory :business_status do
    sequence(:name) { |n| "status_#{n}" }

    trait :available do
      name { 'available' }
    end

    trait :prospecto do
      name { 'prospecto' }
    end
  end
end

