class TransactionScenario < ApplicationRecord
     include AutoSluggable
  has_many :scenario_documents
  has_many :document_types, through: :scenario_documents
  has_many :business_transactions
  
  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { 
    in: %w[compraventa renta_comercial renta_habitacional] 
  }
  
  scope :active, -> { where(active: true) }
  scope :for_category, ->(category) { where(category: category) }
  
  def required_documents_for_party(party_type)
    scenario_documents.joins(:document_type)
                     .where(party_type: [party_type, 'ambos'], required: true)
                     .includes(:document_type)
  end
  
  def document_count_for_party(party_type)
    required_documents_for_party(party_type).count
  end
end
