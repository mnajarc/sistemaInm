class AddDocumentAnalysisAndCoOwnershipToSubmissions < ActiveRecord::Migration[8.0]
  def change
    # ========================================================================
    # ANÁLISIS CON IA
    # ========================================================================
    
    unless column_exists?(:document_submissions, :analysis_status)
      add_column :document_submissions, :analysis_status, :string, default: 'pending'
    end
    
    unless column_exists?(:document_submissions, :analysis_result)
      add_column :document_submissions, :analysis_result, :jsonb, default: {}
    end
    
    unless column_exists?(:document_submissions, :ocr_text)
      add_column :document_submissions, :ocr_text, :text
    end
    
    unless column_exists?(:document_submissions, :legibility_score)
      add_column :document_submissions, :legibility_score, :decimal, precision: 5, scale: 2
    end
    
    unless column_exists?(:document_submissions, :auto_validated)
      add_column :document_submissions, :auto_validated, :boolean, default: false
    end
    
    unless column_exists?(:document_submissions, :validation_notes)
      add_column :document_submissions, :validation_notes, :text
    end
    
    unless column_exists?(:document_submissions, :analyzed_at)
      add_column :document_submissions, :analyzed_at, :datetime
    end
    
    # ========================================================================
    # RELACIONES DE USUARIO
    # ========================================================================
    
    unless column_exists?(:document_submissions, :uploaded_by_id)
      add_reference :document_submissions, :uploaded_by, foreign_key: { to_table: :users }
    end
    
    unless column_exists?(:document_submissions, :validated_by_id)
      add_reference :document_submissions, :validated_by, foreign_key: { to_table: :users }
    end
    
    # ========================================================================
    # COPROPIEDADES (nombre correcto: business_transaction_co_owner)
    # ========================================================================
    
    unless column_exists?(:document_submissions, :business_transaction_co_owner_id)
      add_reference :document_submissions, :business_transaction_co_owner, 
                    foreign_key: true,
                    index: { name: 'idx_doc_sub_on_bt_co_owner_id' }
    end
    
    # ========================================================================
    # ÍNDICES PARA PERFORMANCE
    # ========================================================================
    
    unless index_exists?(:document_submissions, :analysis_status)
      add_index :document_submissions, :analysis_status
    end
    
    unless index_exists?(:document_submissions, :legibility_score)
      add_index :document_submissions, :legibility_score
    end
    
    unless index_exists?(:document_submissions, :auto_validated)
      add_index :document_submissions, :auto_validated
    end
    
    unless index_exists?(:document_submissions, :party_type)
      add_index :document_submissions, :party_type
    end
    
    unless index_exists?(:document_submissions, [:business_transaction_id, :party_type])
      add_index :document_submissions, [:business_transaction_id, :party_type],
                name: 'idx_doc_sub_on_bt_id_and_party'
    end
    
    unless index_exists?(:document_submissions, [:business_transaction_id, :business_transaction_co_owner_id])
      add_index :document_submissions, [:business_transaction_id, :business_transaction_co_owner_id],
                name: 'idx_doc_sub_on_bt_id_and_co_owner_id'
    end
  end
end
