# app/models/scenario_document.rb
class ScenarioDocument < ApplicationRecord
  belongs_to :transaction_scenario
  belongs_to :document_type
  
  validates :party_type, presence: true, inclusion: { 
    in: %w[oferente adquiriente ambos copropietario copropietario_principal] 
  }
  validates :required, inclusion: { in: [true, false] }
  
  scope :required, -> { where(required: true) }
  scope :for_party, ->(party) { where(party_type: [party, 'ambos']) }
  scope :for_oferente, -> { for_party('oferente') }
  scope :for_adquiriente, -> { for_party('adquiriente') }
  scope :for_copropietario, -> { for_party('copropietario') }
  scope :for_copropietario_principal, -> { for_party('copropietario_principal') }
end
