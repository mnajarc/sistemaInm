class RemoveValidationStatusFromDocumentSubmissions < ActiveRecord::Migration[8.0]
  def up
    # Primero elimina la columna
    remove_column :document_submissions, :validation_status
  end

  def down
    # Por si necesitas revertir (aunque no es recomendable)
    add_column :document_submissions, :validation_status, :string, default: 'pending_review'
  end
end
