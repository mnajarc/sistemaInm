# spec/factories/clients.rb
FactoryBot.define do
  factory :client do
    sequence(:first_names) { |n| "Nombre#{n}" }
    sequence(:first_surname) { |n| "Apellido#{n}" }
    second_surname { "Segundo" }
    sequence(:email) { |n| "cliente#{n}@example.com" }
    phone { "55#{rand(10_000_000..99_999_999)}" }
    civil_status { "soltero" }
    active { true }
    # full_name se genera via callback compose_full_name
  end
end
