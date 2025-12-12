# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    full_name { Faker::Name.name }
    role { association :role }  
    
    trait :admin do
      role { 'admin' }
    end
    
    trait :agent do
      role { 'agent' }
    end
    
    trait :superadmin do
      role { 'superadmin' }
    end
  end
end
