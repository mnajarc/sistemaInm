class AddConstraintsToDocumentModels < ActiveRecord::Migration[8.0]
  def change
    # DocumentType constraints
    change_column_null :document_types, :name, false
    change_column_null :document_types, :category, false
    change_column_null :document_types, :valid_from, false
    change_column_null :document_types, :is_active, false, false
    add_index :document_types, :name, unique: true

    # DocumentRequirement constraints
    change_column_null :document_requirements, :property_type, false
    change_column_null :document_requirements, :transaction_type, false
    change_column_null :document_requirements, :client_type, false
    change_column_null :document_requirements, :person_type, false
    change_column_null :document_requirements, :valid_from, false
    change_column_null :document_requirements, :is_required, false, false

    # DocumentValidityRule constraints
    change_column_null :document_validity_rules, :validity_period_months, false
    change_column_null :document_validity_rules, :valid_from, false
    change_column_null :document_validity_rules, :is_active, false, false

    # PropertyDocument constraints
    change_column_null :property_documents, :status, false
    change_column_null :property_documents, :uploaded_at, false
    change_column_null :property_documents, :issued_at, false

    # Check constraints (PostgreSQL/MySQL)
    if connection.adapter_name.downcase.include?('postgresql')
      execute <<-SQL
        ALTER TABLE document_validity_rules#{' '}
        ADD CONSTRAINT validity_period_positive#{' '}
        CHECK (validity_period_months > 0)
      SQL

      execute <<-SQL
        ALTER TABLE document_types#{' '}
        ADD CONSTRAINT valid_until_after_valid_from#{' '}
        CHECK (valid_until IS NULL OR valid_until > valid_from)
      SQL
    end
  end
end
