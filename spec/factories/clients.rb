# spec/factories/clients.rb - CREAR
FactoryBot.define do
  factory :client do
    sequence(:email) { |n| "client#{n}@example.com" }
    name { Faker::Name.name }
  end
end
