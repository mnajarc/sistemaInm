# db/migrate/[timestamp]_create_initial_contact_forms.rb
class CreateInitialContactForms < ActiveRecord::Migration[8.0]
  def change
    create_table :initial_contact_forms do |t|
      # Relaciones
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.references :client, foreign_key: true
      t.references :property, foreign_key: true
      t.references :business_transaction, foreign_key: true
      
      # Estado del formulario
      t.integer :status, default: 0, null: false
      t.datetime :completed_at
      t.datetime :converted_at
      
      # SECCIÓN 1: Condiciones Generales (JSONB)
      t.jsonb :general_conditions, default: {}
      # {
      #   property_acquisition_method: 'compra_directa', # o herencia, donacion, etc
      #   contract_signer_type: 'propietario', # o apoderado, representante_legal
      #   owner_or_representative_name: 'Juan Pérez',
      #   domicile_type: 'casa_habitacion', # departamento, terreno, etc
      #   civil_status: 'soltero', # casado, divorciado, etc
      #   marriage_regime: 'separacion_bienes', # si aplica
      #   notes: 'Información adicional'
      # }
      
      # SECCIÓN 2: Información General del Inmueble
      t.jsonb :property_info, default: {}
      # {
      #   co_owners_count: 1,
      #   acquisition_date: '2020-01-15',
      #   co_owners_relationship: 'ninguno', # hermanos, esposos, etc
      #   property_use: 'habitacional', # comercial, mixto
      #   is_mortgaged: false,
      #   mortgage_bank: 'BBVA',
      #   has_improvements: true,
      #   improvements_description: 'Ampliación de cocina'
      # }
      
      # SECCIÓN 3: Información de Herencias (si aplica)
      t.jsonb :inheritance_info, default: {}
      # {
      #   is_inheritance: false,
      #   heirs_count: 0,
      #   deceased_civil_status: 'casado',
      #   succession_type: 'testamentaria', # intestamentaria
      #   has_court_ruling: true,
      #   ruling_date: '2023-05-10',
      #   notarial_deed_number: '12345',
      #   notary_name: 'Lic. María López',
      #   notary_number: '23',
      #   all_heirs_agree: true
      # }
      
      # SECCIÓN 4: Estatus Actual
      t.jsonb :current_status, default: {}
      # {
      #   has_active_mortgage: false,
      #   mortgage_balance: 0,
      #   monthly_payment: 0,
      #   has_renovations: false,
      #   renovation_permits: [],
      #   is_in_condominium: true,
      #   condominium_regime: 'horizontal',
      #   has_rental_units: false,
      #   rental_units_count: 0
      # }
      
      # SECCIÓN 5: Exención ISR
      t.jsonb :tax_exemption, default: {}
      # {
      #   previous_sales_last_3_years: false,
      #   previous_sale_date: nil,
      #   ine_matches_deed: true,
      #   first_home_sale: true,
      #   lived_last_5_years: true,
      #   qualifies_for_exemption: true,
      #   estimated_capital_gain: 0
      # }
      
      # SECCIÓN 6: Promoción
      t.jsonb :promotion_preferences, default: {}
      # {
      #   allows_signage: true,
      #   signage_types: ['lona', 'se_vende'],
      #   allows_flyers_with_address: true,
      #   allows_open_house: false,
      #   preferred_contact_method: 'telefono',
      #   contact_hours: 'manana',
      #   special_instructions: 'Llamar antes de visitar'
      # }
      
      # Observaciones generales del agente
      t.text :agent_notes
      
      # Metadatos
      t.integer :version, default: 1
      t.string :form_source, default: 'web' # web, mobile, paper
      
      t.timestamps
      
      # Índices
      t.index :status
      t.index :completed_at
      t.index :converted_at
      t.index [:agent_id, :created_at]
    end
  end
end