# spec/services/document_validation_service_spec.rb
require 'rails_helper'

RSpec.describe DocumentValidationService, type: :service do
  let(:document_submission) { create(:document_submission) }
  let(:admin_user) { create(:user, :admin) }
  let(:service) { DocumentValidationService.new(document_submission) }

  describe '#approve!' do
    it 'updates validation_status to approved' do
      service.approve!(admin_user)
      expect(document_submission.reload.validation_status).to eq('approved')
    end

    it 'sets validation_user' do
      service.approve!(admin_user)
      expect(document_submission.reload.validation_user).to eq(admin_user)
    end

    it 'sets validated_at timestamp' do
      expect {
        service.approve!(admin_user)
      }.to change { document_submission.reload.validated_at }
    end

    it 'creates a status_change note' do
      expect {
        service.approve!(admin_user, "Looks good")
      }.to change(DocumentNote, :count).by(2) # status_change + comment
    end

    it 'creates a comment note if provided' do
      service.approve!(admin_user, "Approved")
      note = document_submission.document_notes.where(note_type: 'comment').last
      expect(note.content).to include("Approved")
    end
  end

  describe '#reject!' do
    it 'updates validation_status to rejected' do
      service.reject!(admin_user, "Missing signature")
      expect(document_submission.reload.validation_status).to eq('rejected')
    end

    it 'clears submitted_at to allow re-upload' do
      document_submission.update(submitted_at: Time.current)
      service.reject!(admin_user, "Missing signature")
      expect(document_submission.reload.submitted_at).to be_nil
    end

    it 'creates status_change and comment notes' do
      expect {
        service.reject!(admin_user, "Needs revision")
      }.to change(DocumentNote, :count).by(2)
    end
  end

  describe '#mark_expired!' do
    it 'updates validation_status to expired' do
      service.mark_expired!(admin_user)
      expect(document_submission.reload.validation_status).to eq('expired')
    end

    it 'creates status_change note' do
      expect {
        service.mark_expired!(admin_user, "Vigencia vencida")
      }.to change(DocumentNote, :count).by(2)
    end
  end

  describe '#add_note' do
    it 'creates a new document note' do
      expect {
        service.add_note(admin_user, "Test note")
      }.to change(DocumentNote, :count).by(1)
    end

    it 'raises error if content is blank' do
      expect {
        service.add_note(admin_user, "")
      }.to raise_error(StandardError)
    end
  end

  describe '#delete_last_note' do
    let!(:note1) { document_submission.add_note(admin_user, "First note") }
    let!(:note2) { document_submission.add_note(admin_user, "Second note") }

    it 'deletes the last note' do
      expect {
        service.delete_last_note(admin_user)
      }.to change(DocumentNote, :count).by(-1)
    end

    it 'raises error if not author' do
      other_user = create(:user)
      expect {
        service.delete_last_note(other_user)
      }.to raise_error(StandardError)
    end

    it 'raises error if trying to delete old note' do
      service.delete_last_note(admin_user)
      expect {
        service.delete_last_note(admin_user)
      }.to raise_error(StandardError)
    end
  end

  describe '.check_and_mark_expired!' do
    let!(:expired_doc) { create(:document_submission, expiry_date: 1.day.ago, validation_status: 'approved') }
    let!(:valid_doc) { create(:document_submission, expiry_date: 1.day.from_now, validation_status: 'approved') }

    it 'marks expired documents' do
      DocumentValidationService.check_and_mark_expired!
      expect(expired_doc.reload.validation_status).to eq('expired')
    end

    it 'does not mark valid documents' do
      DocumentValidationService.check_and_mark_expired!
      expect(valid_doc.reload.validation_status).to eq('approved')
    end
  end
end
