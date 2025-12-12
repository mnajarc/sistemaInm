# spec/factories/business_statuses.rb - CREAR
FactoryBot.define do
  factory :business_status do
    sequence(:name) { |n| "status_#{n}" }
  end
end
