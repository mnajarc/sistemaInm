# spec/factories/properties.rb - CREAR
FactoryBot.define do
  factory :property do
    user { association :user }
    address { Faker::Address.full_address }
    price { Faker::Commerce.price(range: 100000..1000000) }
  end
end
