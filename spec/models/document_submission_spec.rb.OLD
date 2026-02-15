# spec/models/document_submission_spec.rb
require 'rails_helper'

RSpec.describe DocumentSubmission, type: :model do
  let(:submission) { create(:document_submission) }
  let(:admin_user) { create(:user, :admin) }

  # Associations
  describe 'associations' do
    it { is_expected.to have_many(:document_notes).dependent(:destroy) }
    it { is_expected.to belong_to(:business_transaction) }
    it { is_expected.to belong_to(:document_type) }
    it { is_expected.to belong_to(:business_transaction_co_owner).optional }
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:validation_status) }
    it { is_expected.to validate_inclusion_of(:validation_status).in_array(%w[pending_review approved rejected expired]) }
    it { is_expected.to validate_presence_of(:party_type) }
    it { is_expected.to validate_inclusion_of(:party_type).in_array(%w[oferente adquiriente copropietario copropietario_principal]) }
  end

  # Methods
  describe '#can_reupload?' do
    context 'when rejected' do
      before { submission.update(validation_status: 'rejected') }
      it { expect(submission.can_reupload?).to be true }
    end

    context 'when expired' do
      before { submission.update(validation_status: 'expired') }
      it { expect(submission.can_reupload?).to be true }
    end

    context 'when approved' do
      before { submission.update(validation_status: 'approved') }
      it { expect(submission.can_reupload?).to be false }
    end

    context 'when not uploaded' do
      before { submission.update(submitted_at: nil) }
      it { expect(submission.can_reupload?).to be true }
    end
  end

  describe '#is_expired?' do
    context 'when expiry_date is in the past' do
      before { submission.update(expiry_date: 1.day.ago) }
      it { expect(submission.is_expired?).to be true }
    end

    context 'when expiry_date is in the future' do
      before { submission.update(expiry_date: 1.day.from_now) }
      it { expect(submission.is_expired?).to be false }
    end

    context 'when no expiry_date' do
      before { submission.update(expiry_date: nil) }
      it { expect(submission.is_expired?).to be false }
    end
  end

  describe '#add_note' do
    it 'creates a new note' do
      expect {
        submission.add_note(admin_user, "Test note")
      }.to change(DocumentNote, :count).by(1)
    end

    it 'associates note with correct user' do
      submission.add_note(admin_user, "Test note")
      expect(submission.document_notes.last.user).to eq(admin_user)
    end
  end

  describe '#last_note' do
    let!(:note1) { submission.add_note(admin_user, "First") }
    let!(:note2) { submission.add_note(admin_user, "Second") }

    it { expect(submission.last_note).to eq(note2) }
  end
end
