# spec/factories/business_transactions.rb
FactoryBot.define do
  factory :business_transaction do
    listing_agent { association(:user, :agent) }
    current_agent { listing_agent }
    offering_client { association(:client) }
    property { association(:property) }
    operation_type { association(:operation_type, :venta) }
    business_status { association(:business_status, :available) }
    price { rand(500_000..5_000_000) }
    start_date { Date.current }
    commission_percentage { 5.0 }
    # transaction_scenario es optional — no forzar
  end
end
