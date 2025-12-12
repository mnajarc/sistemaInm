# spec/models/document_note_spec.rb
require 'rails_helper'

RSpec.describe DocumentNote, type: :model do
  let(:document_submission) { create(:document_submission) }
  let(:user) { create(:user) }
  let(:document_note) { create(:document_note, document_submission: document_submission, user: user) }

  describe 'associations' do
    it { should belong_to(:document_submission) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:note_type) }
    it { should validate_inclusion_of(:note_type).in_array(%w[comment status_change]) }
  end

  describe '#deletable_by?' do
    context 'when user is the author and it is the last note' do
      it { expect(document_note.deletable_by?(user)).to be true }
    end

    context 'when user is not the author' do
      let(:other_user) { create(:user) }
      it { expect(document_note.deletable_by?(other_user)).to be false }
    end

    context 'when it is not the last note' do
      before { create(:document_note, document_submission: document_submission, user: user) }
      it { expect(document_note.deletable_by?(user)).to be false }
    end
  end

  describe 'scopes' do
    let!(:comment) { create(:document_note, document_submission: document_submission, note_type: 'comment') }
    let!(:status_change) { create(:document_note, document_submission: document_submission, note_type: 'status_change') }

    describe '.comments' do
      it { expect(DocumentNote.comments).to include(comment) }
      it { expect(DocumentNote.comments).not_to include(status_change) }
    end

    describe '.status_changes' do
      it { expect(DocumentNote.status_changes).to include(status_change) }
      it { expect(DocumentNote.status_changes).not_to include(comment) }
    end

    describe '.recent' do
      it 'returns notes in reverse chronological order' do
        expect(DocumentNote.recent.first).to eq(status_change)
      end
    end
  end
end
