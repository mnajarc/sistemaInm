# spec/factories/properties.rb
FactoryBot.define do
  factory :property do
    user { association(:user) }
    property_type { PropertyType.first || association(:property_type) }
    sequence(:address) { |n| "Calle #{n} #100, Col. Centro, CDMX" }
    sequence(:street) { |n| "Calle #{n}" }
    exterior_number { "100" }
    neighborhood { "Centro" }
    municipality { "Cuauhtémoc" }
    city { "Ciudad de México" }
    postal_code { "06000" }
    price { rand(500_000..5_000_000) }
    built_area_m2 { rand(50..300).to_f }
    lot_area_m2 { rand(80..500).to_f }
  end
end

