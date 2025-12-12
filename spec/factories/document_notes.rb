# spec/factories/document_notes.rb
FactoryBot.define do
  factory :document_note do
    document_submission
    user
    content { Faker::Lorem.paragraph }
    note_type { 'comment' }
  end
end

# spec/factories/document_submissions.rb - ACTUALIZAR
FactoryBot.define do
  factory :document_submission do
    business_transaction
    document_type
    user { association :user, :agent }
    party_type { 'copropietario_principal' }
    validation_status { 'pending_review' }
    submitted_at { 1.day.ago }
    expiry_date { 3.months.from_now }
  end
end
