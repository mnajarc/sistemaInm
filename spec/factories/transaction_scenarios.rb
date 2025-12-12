# spec/factories/transaction_scenarios.rb - CREAR
FactoryBot.define do
  factory :transaction_scenario do
    sequence(:name) { |n| "Scenario #{n}" }
    category { 'compraventa' }
  end
end
