# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:full_name) { |n| "Usuario Test #{n}" }

    # Si role es belongs_to :role (modelo Role)
    role { association(:role) }

    trait :admin do
      role { association(:role, name: 'admin') }
    end

    trait :agent do
      role { association(:role, name: 'agent') }
      after(:create) do |user|
        create(:agent, user: user) unless user.agent.present?
      end
    end

    trait :superadmin do
      role { association(:role, name: 'superadmin') }
    end
  end
end
