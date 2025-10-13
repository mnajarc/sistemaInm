class AddDetailedAddressToProperties < ActiveRecord::Migration[8.0]
  def change
    # Dirección detallada
    add_column :properties, :street, :string
    add_column :properties, :exterior_number, :string
    add_column :properties, :interior_number, :string
    add_column :properties, :neighborhood, :string
    add_column :properties, :municipality, :string
    add_column :properties, :country, :string, default: 'México'
    
    # Características legales permanentes
    add_column :properties, :has_extensions, :boolean, default: false
    add_column :properties, :land_use, :string
    
    # Índices para búsquedas frecuentes
    add_index :properties, :street
    add_index :properties, :neighborhood
    add_index :properties, :municipality
    add_index :properties, [:city, :state, :municipality], name: 'index_properties_location'
    add_index :properties, :land_use
  end
end