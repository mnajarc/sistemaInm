# db/migrate/XXXXXX_create_document_reviews.rb
class CreateDocumentReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :document_reviews do |t|
      t.references :document_submission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      t.string :action, null: false  # validado, rechazado, solicitado_correccion
      t.text :notes
      t.datetime :reviewed_at, null: false
      
      # Para auditoría: estado anterior y nuevo
      t.string :previous_status
      t.string :new_status
      
      # Metadata adicional (opcional)
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    # Índices para búsquedas comunes
    add_index :document_reviews, :action
    add_index :document_reviews, :reviewed_at
    add_index :document_reviews, [:document_submission_id, :reviewed_at]
  end
end
