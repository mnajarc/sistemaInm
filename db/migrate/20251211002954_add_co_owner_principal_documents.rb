# db/migrate/[timestamp]_add_co_owner_principal_documents.rb
class AddCoOwnerPrincipalDocuments < ActiveRecord::Migration[8.0]
  def up
    # Obtener todos los scenarios
    TransactionScenario.find_each do |scenario|
      # Para cada scenario que tiene documentos 'copropietario'
      # duplicarlos como 'copropietario_principal'
      
      copropietario_docs = ScenarioDocument.where(
        transaction_scenario_id: scenario.id,
        party_type: 'copropietario'
      )
      
      copropietario_docs.each do |doc|
        # Crear copia con party_type 'copropietario_principal'
        ScenarioDocument.create!(
          transaction_scenario_id: doc.transaction_scenario_id,
          document_type_id: doc.document_type_id,
          party_type: 'copropietario_principal',
          required: doc.required,
        )
      end
    end
  end

  def down
    ScenarioDocument.where(party_type: 'copropietario_principal').delete_all
  end
end
