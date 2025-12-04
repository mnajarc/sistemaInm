class ImproveClientNameStructure < ActiveRecord::Migration[7.0]
  def change
    # ✅ AGREGAR NUEVAS COLUMNAS
    add_column :clients, :first_names, :string, comment: "Nombre(s) propios: Isabel María Luisa"
    add_column :clients, :first_surname, :string, comment: "Primer apellido: Calderón"
    add_column :clients, :second_surname, :string, comment: "Segundo apellido: Grajales (opcional)"
    
    # ✅ MIGRAR DATOS EXISTENTES (fallback simple)
    # En producción, esto dependerá de tu lógica actual
    reversible do |dir|
      dir.up do
        # Si existen clientes, intentar extraer (con limitaciones)
        execute <<-SQL
          UPDATE clients 
          SET first_names = name, 
              first_surname = '',
              second_surname = ''
          WHERE first_names IS NULL
        SQL
      end
    end
    
    # ✅ ÍNDICES PARA BÚSQUEDAS
    add_index :clients, :first_names
    add_index :clients, :first_surname
    add_index :clients, :second_surname
  end
end
