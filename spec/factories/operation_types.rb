# spec/factories/operation_types.rb
FactoryBot.define do
  factory :operation_type do
    sequence(:name) { |n| "operation_#{n}" }
    sort_order { 1 }

    trait :venta do
      name { 'venta' }
    end

    trait :renta do
      name { 'renta' }
    end
  end
end

