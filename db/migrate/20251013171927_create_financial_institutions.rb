class CreateFinancialInstitutions < ActiveRecord::Migration[8.0]
  def change
    create_table :financial_institutions do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :institution_type # Banco, Sofom, Unión de Crédito, etc.
      t.string :code # Código de institución bancaria
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :financial_institutions, :name, unique: true
    add_index :financial_institutions, :code
    add_index :financial_institutions, :institution_type
    add_index :financial_institutions, :active
  end
end