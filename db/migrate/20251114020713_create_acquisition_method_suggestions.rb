class CreateAcquisitionMethodSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :acquisition_method_suggestions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :initial_contact_form, foreign_key: true, null: true
      
      t.string :suggested_name, null: false
      t.text :legal_basis, null: false
      t.string :status, default: 'pending'
      
      t.references :merged_with, foreign_key: { to_table: :property_acquisition_methods }, null: true
      t.text :admin_notes
      
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }, null: true
      
      t.timestamps
    end
    
    add_index :acquisition_method_suggestions, :status
    add_index :acquisition_method_suggestions, [:user_id, :created_at]
  end
end
