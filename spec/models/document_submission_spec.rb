# spec/models/document_submission_spec.rb
require 'rails_helper'

RSpec.describe DocumentSubmission, type: :model do
  let(:business_transaction) { create(:business_transaction) }
  let(:document_submission) { create(:document_submission, business_transaction: business_transaction) }
  let(:user) { create(:user, :admin) }

  describe 'associations' do
    it { should have_many(:document_notes).dependent(:destroy) }
    it { should belong_to(:business_transaction) }
    it { should belong_to(:document_type) }
  end

  describe 'validations' do
    it { should validate_presence_of(:validation_status) }
    it { should validate_inclusion_of(:validation_status).in_array(%w[pending_review approved rejected expired]) }
    it { should validate_presence_of(:party_type) }
    it { should validate_inclusion_of(:party_type).in_array(%w[oferente adquiriente copropietario copropietario_principal]) }
  end

  describe '#can_reupload?' do
    context 'when rejected' do
      before { document_submission.update(validation_status: 'rejected') }
      it { expect(document_submission.can_reupload?).to be true }
    end

    context 'when expired' do
      before { document_submission.update(validation_status: 'expired') }
      it { expect(document_submission.can_reupload?).to be true }
    end

    context 'when approved' do
      before { document_submission.update(validation_status: 'approved') }
      it { expect(document_submission.can_reupload?).to be false }
    end

    context 'when not uploaded' do
      before { document_submission.update(submitted_at: nil) }
      it { expect(document_submission.can_reupload?).to be true }
    end
  end

  describe '#is_expired?' do
    context 'when expiry_date is in the past' do
      before { document_submission.update(expiry_date: 1.day.ago) }
      it { expect(document_submission.is_expired?).to be true }
    end

    context 'when expiry_date is in the future' do
      before { document_submission.update(expiry_date: 1.day.from_now) }
      it { expect(document_submission.is_expired?).to be false }
    end

    context 'when no expiry_date' do
      before { document_submission.update(expiry_date: nil) }
      it { expect(document_submission.is_expired?).to be false }
    end
  end

  describe '#add_note' do
    it 'creates a new note' do
      expect {
        document_submission.add_note(user, "Test note")
      }.to change(DocumentNote, :count).by(1)
    end

    it 'associates note with correct user' do
      document_submission.add_note(user, "Test note")
      expect(document_submission.document_notes.last.user).to eq(user)
    end
  end

  describe '#last_note' do
    it 'returns the most recent note' do
      first_note = document_submission.add_note(user, "First note")
      second_note = document_submission.add_note(user, "Second note")
      
      expect(document_submission.last_note).to eq(second_note)
    end
  end
end
