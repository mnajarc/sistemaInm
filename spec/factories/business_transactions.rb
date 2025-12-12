# spec/factories/business_transactions.rb
FactoryBot.define do
  factory :business_transaction do
    listing_agent { association :user, :agent }
    current_agent { association :user, :agent }
    offering_client { association :client }
    property { association :property }
    operation_type { association :operation_type }
    business_status { association :business_status }
    price { Faker::Commerce.price(range: 100000..1000000) }
    start_date { Date.current }
    transaction_scenario { association :transaction_scenario }
  end
end
