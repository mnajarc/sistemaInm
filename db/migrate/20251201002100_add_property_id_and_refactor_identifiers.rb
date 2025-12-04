class AddPropertyIdAndRefactorIdentifiers < ActiveRecord::Migration[7.0]
  def change
    # ═══════════════════════════════════════════════════════════
    # PASO 1: AGREGAR COLUMNA SIN NOT NULL
    # ═══════════════════════════════════════════════════════════
    unless column_exists?(:properties, :property_id)
      add_column :properties, :property_id, :string
      add_column :properties, :property_id_generated_at, :datetime
    end

    # ═══════════════════════════════════════════════════════════
    # PASO 2: GENERAR PROPERTY IDs PARA DATOS EXISTENTES
    # ═══════════════════════════════════════════════════════════
    reversible do |dir|
      dir.up do
        Property.reset_column_information
        
        Property.find_each do |property|
          next if property.property_id.present?
          
          # Generar property_id basado en ubicación
          street_norm = I18n.transliterate(property.street.to_s)
            .downcase
            .gsub(/[^a-z0-9]/, '')
            .slice(0, 15)
          
          ext_norm = property.exterior_number.to_s
            .gsub(/[^a-z0-9]/, '')
            .upcase
            .slice(0, 6)
          
          municipality_norm = I18n.transliterate(property.municipality.to_s)
            .downcase
            .gsub(/[^a-z0-9]/, '')
            .slice(0, 8)
          
          state_code = property.state.to_s.slice(0, 3).upcase
          
          type_code = case property.property_type&.name&.downcase
                      when /casa|vivienda|habitacion|unifamiliar/ then 'C'
                      when /departamento|apartamento|piso/ then 'D'
                      when /comercial|local|tienda/ then 'L'
                      when /bodega|industrial|nave/ then 'B'
                      when /terreno|lote/ then 'T'
                      when /oficina|consultorio/ then 'O'
                      else 'X'
                      end
          
          generated_id = "#{street_norm.upcase}-#{ext_norm}-#{municipality_norm.upcase}-#{state_code}-#{type_code}"
          
          # Actualizar sin validaciones
          property.update_column(:property_id, generated_id)
          property.update_column(:property_id_generated_at, Time.current)
          
          puts "✓ Generado #{generated_id} para propiedad #{property.id}"
        end
      end
      
      dir.down do
        # En rollback, simplemente eliminar los datos
        if column_exists?(:properties, :property_id)
          Property.update_all(property_id: nil, property_id_generated_at: nil)
        end
      end
    end

    # ═══════════════════════════════════════════════════════════
    # PASO 3: AGREGAR CONSTRAINS DE UNICIDAD Y NOT NULL
    # ═══════════════════════════════════════════════════════════
    change_column_null :properties, :property_id, false
    
    unless index_exists?(:properties, :property_id)
      add_index :properties, :property_id, unique: true
    end

    # Agregar constraint de unicidad en ubicación
    unless index_exists?(:properties, 
                         [:street, :exterior_number, :neighborhood, :municipality, :state, :country])
      add_index :properties, 
                [:street, :exterior_number, :neighborhood, :municipality, :state, :country],
                unique: true,
                name: "idx_properties_unique_location"
    end

    # ═══════════════════════════════════════════════════════════
    # AGREGAR COLUMNAS A INITIAL_CONTACT_FORMS
    # ═══════════════════════════════════════════════════════════
    
    unless column_exists?(:initial_contact_forms, :opportunity_identifier)
      if column_exists?(:initial_contact_forms, :property_human_identifier)
        rename_column :initial_contact_forms, :property_human_identifier, :opportunity_identifier
      else
        add_column :initial_contact_forms, :opportunity_identifier, :string
      end
    end
    
    add_column :initial_contact_forms, :opportunity_identifier_generated_at, :datetime unless column_exists?(:initial_contact_forms, :opportunity_identifier_generated_at)
    
    unless index_exists?(:initial_contact_forms, :opportunity_identifier)
      add_index :initial_contact_forms, :opportunity_identifier, unique: true
    end

    unless column_exists?(:initial_contact_forms, :property_id)
      add_reference :initial_contact_forms, :property, foreign_key: true
    end

    # ═══════════════════════════════════════════════════════════
    # CREAR TABLA CO_OWNERSHIP_LINKS
    # ═══════════════════════════════════════════════════════════
    unless table_exists?(:co_ownership_links)
      create_table :co_ownership_links do |t|
        t.references :primary_client, foreign_key: { to_table: :clients }, null: false
        t.references :co_owner_client, foreign_key: { to_table: :clients }, null: false
        t.references :initial_contact_form, foreign_key: true
        t.references :business_transaction, foreign_key: true
        t.decimal :ownership_percentage, precision: 5, scale: 2, default: 0
        t.string :co_owner_opportunity_id, null: false
        t.string :relationship_type
        t.text :notes

        t.timestamps
      end

      add_index :co_ownership_links, :co_owner_opportunity_id, unique: true
      add_index :co_ownership_links, 
                [:primary_client_id, :co_owner_client_id],
                unique: true,
                name: 'idx_co_ownership_unique'
    end

    # ═══════════════════════════════════════════════════════════
    # AGREGAR COLUMNAS A CLIENTS
    # ═══════════════════════════════════════════════════════════
    add_column :clients, :client_identifier, :string unless column_exists?(:clients, :client_identifier)
    add_column :clients, :client_identifier_generated_at, :datetime unless column_exists?(:clients, :client_identifier_generated_at)
    add_column :clients, :complete_at, :datetime unless column_exists?(:clients, :complete_at)
    add_column :clients, :internal_notes, :text unless column_exists?(:clients, :internal_notes)
    
    add_index :clients, :client_identifier, unique: true unless index_exists?(:clients, :client_identifier)
  end
end
