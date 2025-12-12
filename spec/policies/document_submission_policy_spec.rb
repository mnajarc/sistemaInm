# spec/policies/document_submission_policy_spec.rb
require 'rails_helper'

RSpec.describe DocumentSubmissionPolicy do
  let(:admin_user) { create(:user, :admin) }
  let(:agent_user) { create(:user, :agent) }
  let(:other_agent) { create(:user, :agent) }
  let(:business_transaction) { create(:business_transaction, current_agent: agent_user) }
  let(:document_submission) { create(:document_submission, business_transaction: business_transaction) }

  subject { DocumentSubmissionPolicy.new(admin_user, document_submission) }

  describe '#index?' do
    it { expect(DocumentSubmissionPolicy.new(admin_user, document_submission).index?).to be true }
    it { expect(DocumentSubmissionPolicy.new(agent_user, document_submission).index?).to be true }
  end

  describe '#approve?' do
    it { expect(DocumentSubmissionPolicy.new(admin_user, document_submission).approve?).to be true }
    it { expect(DocumentSubmissionPolicy.new(agent_user, document_submission).approve?).to be false }
  end

  describe '#reject?' do
    it { expect(DocumentSubmissionPolicy.new(admin_user, document_submission).reject?).to be true }
    it { expect(DocumentSubmissionPolicy.new(agent_user, document_submission).reject?).to be false }
  end

  describe '#add_note?' do
    it { expect(DocumentSubmissionPolicy.new(admin_user, document_submission).add_note?).to be true }
    it { expect(DocumentSubmissionPolicy.new(agent_user, document_submission).add_note?).to be true }
  end

  describe '#delete_note?' do
    let!(:note) { create(:document_note, document_submission: document_submission, user: agent_user) }

    context 'when user is author of last note' do
      it { expect(DocumentSubmissionPolicy.new(agent_user, document_submission).delete_note?).to be true }
    end

    context 'when user is not author' do
      it { expect(DocumentSubmissionPolicy.new(other_agent, document_submission).delete_note?).to be false }
    end
  end
end
