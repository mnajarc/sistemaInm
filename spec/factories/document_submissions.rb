# spec/factories/document_submissions.rb - ACTUALIZAR
FactoryBot.define do
  factory :document_submission do
    business_transaction { association :business_transaction }
    document_type { association :document_type }
    party_type { 'copropietario_principal' }
    validation_status { 'pending_review' }
    submitted_at { 1.day.ago }
    expiry_date { 3.months.from_now }
  end
end
