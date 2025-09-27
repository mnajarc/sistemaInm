class CreateBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :business_transactions do |t|
      # Referencias principales
      t.references :property, null: false, foreign_key: true
      t.references :operation_type, null: false, foreign_key: true
      t.references :business_status, null: false, foreign_key: true

      # Clientes (la base es el ofertante)
      t.references :offering_client, null: false, foreign_key: { to_table: :clients }
      t.references :acquiring_client, null: true, foreign_key: { to_table: :clients }

      # Agente responsable
      t.references :agent, null: false, foreign_key: { to_table: :users }

      # Fechas del negocio
      t.date :start_date, null: false
      t.date :estimated_completion_date
      t.date :actual_completion_date

      # Términos financieros
      t.decimal :price, precision: 15, scale: 2, null: false
      t.decimal :commission_percentage, precision: 5, scale: 2, default: 0.0

      # Información adicional
      t.text :notes
      t.text :terms_and_conditions

      # Metadata
      t.boolean :is_primary, default: false  # Si es el negocio principal de la propiedad

      t.timestamps
    end

    # Índices para optimización
    add_index :business_transactions, [ :property_id, :is_primary ]
    add_index :business_transactions, :start_date
  end
end
