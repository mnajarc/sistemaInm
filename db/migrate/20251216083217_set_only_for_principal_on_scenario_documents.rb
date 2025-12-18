# db/migrate/TIMESTAMP_set_only_for_principal_on_scenario_documents.rb
class SetOnlyForPrincipalOnScenarioDocuments < ActiveRecord::Migration[8.0]
  def up
    # Documentos que SOLO el principal debe proporcionar
    principal_only_docs = [
      'Testamento',
      'Boleta predial',
      'Certificado de libertad de gravamen',
      'Declaratoria de herederos',
      'Título de propiedad',
      'Acta de defunción',
      'Adjudicación Notarial'
    ]
    
    # Actualizar todos los ScenarioDocuments que correspondan
    doc_ids = DocumentType.where(name: principal_only_docs).pluck(:id)
    ScenarioDocument.where(document_type_id: doc_ids).update_all(only_for_principal: true)
    
    Rails.logger.info "✅ Documentos de principal-only actualizados: #{ScenarioDocument.where(only_for_principal: true).count}"
  end
  
  def down
    # Revertir si es necesario
    ScenarioDocument.update_all(only_for_principal: false)
  end
end