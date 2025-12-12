# spec/factories/document_types.rb - CREAR
FactoryBot.define do
  factory :document_type do
    sequence(:name) { |n| "Document Type #{n}" }
    category { 'financial' }
  end
end

