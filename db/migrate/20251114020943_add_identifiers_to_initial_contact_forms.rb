
class AddIdentifiersToInitialContactForms < ActiveRecord::Migration[8.0]
  def change
    add_column :initial_contact_forms, :initial_contact_folio, :string
    add_index :initial_contact_forms, :initial_contact_folio, unique: true
    
    add_reference :initial_contact_forms, :property_acquisition_method, foreign_key: true, null: true
    
    add_column :initial_contact_forms, :property_human_identifier, :string
    add_column :initial_contact_forms, :acquisition_details, :jsonb, default: {}
    
    add_index :initial_contact_forms, :acquisition_details, using: :gin
  end
end

