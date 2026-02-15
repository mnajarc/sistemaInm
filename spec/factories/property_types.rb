# spec/factories/property_types.rb
FactoryBot.define do
  factory :property_type do
    sequence(:name) { |n| "tipo_#{n}" }
    description { "Tipo de propiedad de prueba" }
  end
end

