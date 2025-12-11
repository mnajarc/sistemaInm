class UpdateClientTableStructure < ActiveRecord::Migration[8.0]
  def change
    # Agregar campos si no existen
    add_column :clients, :civil_status, :string unless column_exists?(:clients, :civil_status)
    add_column :clients, :marriage_regime_id, :integer unless column_exists?(:clients, :marriage_regime_id)
    add_column :clients, :notes, :text unless column_exists?(:clients, :notes)

    # Renombrar 'name' a 'full_name' (si no existe ya)
    unless column_exists?(:clients, :full_name)
      rename_column :clients, :name, :full_name
    end

    # Asegurar que existen campos de nombres desglosados
    add_column :clients, :first_names, :string unless column_exists?(:clients, :first_names)
    add_column :clients, :first_surname, :string unless column_exists?(:clients, :first_surname)
    add_column :clients, :second_surname, :string unless column_exists?(:clients, :second_surname)

    # Índice único en email para identificar clientes
    add_index :clients, :email, unique: true, if_not_exists: true
  end
end
