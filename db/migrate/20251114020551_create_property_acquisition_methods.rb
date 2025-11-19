class CreatePropertyAcquisitionMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :property_acquisition_methods do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.text :legal_reference
      t.string :legal_act_type
      
      # Flags para validaciones automáticas
      t.boolean :requires_heirs, default: false
      t.boolean :requires_coowners, default: false
      t.boolean :requires_judicial_sentence, default: false
      t.boolean :requires_notary, default: false
      t.boolean :requires_power_of_attorney, default: false
      
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      
      t.timestamps
    end
    
    add_index :property_acquisition_methods, :code, unique: true
    add_index :property_acquisition_methods, :active
    add_index :property_acquisition_methods, :sort_order
  end
end

