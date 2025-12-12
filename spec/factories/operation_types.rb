# spec/factories/operation_types.rb - CREAR
FactoryBot.define do
  factory :operation_type do
    sequence(:name) { |n| "operation_type_#{n}" }
  end
end
