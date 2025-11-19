class AddJsonbIndexesToInitialContactForms < ActiveRecord::Migration[8.0]
  def change
    # Índice GIN para búsquedas JSONB
    add_index :initial_contact_forms, :general_conditions, using: :gin
    # add_index :initial_contact_forms, :acquisition_details, using: :gin
    add_index :initial_contact_forms, :current_status, using: :gin
    
    # Índices específicos para campos consultados frecuentemente
    add_index :initial_contact_forms, 
              "(general_conditions->>'owner_or_representative_name')", 
              name: 'idx_icf_owner_name'
    
    add_index :initial_contact_forms, 
              "(acquisition_details->>'state')", 
              name: 'idx_icf_state'

  end
end
