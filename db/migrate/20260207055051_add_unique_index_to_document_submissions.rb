# db/migrate/20260207055051_add_unique_index_to_document_submissions.rb
class AddUniqueIndexToDocumentSubmissions < ActiveRecord::Migration[8.0]
  # ✅ CLAVE: Deshabilitar transacción automática
  disable_ddl_transaction!

  def up
    # ============================================================
    # PASO 1: Limpiar duplicados existentes
    # ============================================================
    say "Limpiando duplicados existentes en document_submissions..."
    
    # Esta query SÍ necesita transacción explícita
    ActiveRecord::Base.transaction do
      duplicates_sql = <<-SQL
        WITH duplicates AS (
          SELECT 
            id,
            ROW_NUMBER() OVER (
              PARTITION BY 
                business_transaction_id, 
                document_type_id, 
                business_transaction_co_owner_id
              ORDER BY created_at DESC, id DESC
            ) AS row_num
          FROM document_submissions
          WHERE business_transaction_co_owner_id IS NOT NULL
        )
        DELETE FROM document_submissions
        WHERE id IN (
          SELECT id FROM duplicates WHERE row_num > 1
        );
      SQL
      
      result = execute(duplicates_sql)
      say "✅ Eliminados #{result.cmd_tuples} registros duplicados con co-owner", true
    end
    
    # ============================================================
    # PASO 2: Índice único para documentos con co-owner específico
    # ============================================================
    say "Creando índice único para documentos por co-owner..."
    
    # CONCURRENTLY corre FUERA de transacción (gracias a disable_ddl_transaction!)
    add_index :document_submissions,
      [:business_transaction_id, :document_type_id, :business_transaction_co_owner_id],
      unique: true,
      where: "business_transaction_co_owner_id IS NOT NULL",
      name: 'idx_unique_doc_per_co_owner',
      algorithm: :concurrently
    
    say "✅ Índice idx_unique_doc_per_co_owner creado", true
    
    # ============================================================
    # PASO 3: Limpiar duplicados sin co-owner
    # ============================================================
    say "Limpiando duplicados a nivel transacción..."
    
    ActiveRecord::Base.transaction do
      duplicates_transaction_sql = <<-SQL
        WITH duplicates AS (
          SELECT 
            id,
            ROW_NUMBER() OVER (
              PARTITION BY 
                business_transaction_id, 
                document_type_id,
                party_type
              ORDER BY created_at DESC, id DESC
            ) AS row_num
          FROM document_submissions
          WHERE business_transaction_co_owner_id IS NULL
        )
        DELETE FROM document_submissions
        WHERE id IN (
          SELECT id FROM duplicates WHERE row_num > 1
        );
      SQL
      
      result = execute(duplicates_transaction_sql)
      say "✅ Eliminados #{result.cmd_tuples} duplicados sin co-owner", true
    end
    
    # ============================================================
    # PASO 4: Índice único para documentos sin co-owner
    # ============================================================
    say "Creando índice único para documentos a nivel transacción..."
    
    add_index :document_submissions,
      [:business_transaction_id, :document_type_id, :party_type],
      unique: true,
      where: "business_transaction_co_owner_id IS NULL",
      name: 'idx_unique_doc_per_transaction',
      algorithm: :concurrently
    
    say "✅ Índice idx_unique_doc_per_transaction creado", true
    
    # ============================================================
    # PASO 5: Verificación de integridad
    # ============================================================
    say "Verificando integridad de datos..."
    
    verification_sql = <<-SQL
      SELECT 
        COUNT(*) as total,
        COUNT(DISTINCT business_transaction_id) as transactions,
        COUNT(DISTINCT document_type_id) as doc_types
      FROM document_submissions;
    SQL
    
    result = execute(verification_sql).first
    say "📊 Total submissions: #{result['total']}", true
    say "📊 Transacciones únicas: #{result['transactions']}", true
    say "📊 Tipos de documento únicos: #{result['doc_types']}", true
  end

  def down
    say "Eliminando índices únicos..."
    
    # CONCURRENTLY también en el rollback
    remove_index :document_submissions, 
      name: 'idx_unique_doc_per_co_owner',
      algorithm: :concurrently
    
    remove_index :document_submissions,
      name: 'idx_unique_doc_per_transaction',
      algorithm: :concurrently
    
    say "✅ Índices eliminados", true
  end
end
