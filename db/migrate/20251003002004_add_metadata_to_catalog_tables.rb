class AddMetadataToCatalogTables < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'btree_gin' unless extension_enabled?('btree_gin')

    # Agregar metadatos a todas las tablas de catálogos
    catalog_tables = [
      :business_statuses,
      :operation_types, 
      :property_types,
      :co_ownership_types,
      :co_ownership_roles,
      :document_types,
      :property_statuses,
      :roles
    ]
    
    catalog_tables.each do |table|
      add_column table, :metadata, :jsonb, default: {}, null: false
      add_index table, :metadata, using: :gin
      add_column table, :icon, :string unless column_exists?(table, :icon)

    end
    
    # Agregar campos faltantes específicos
    unless column_exists?(:business_statuses, :minimum_role_level)
      add_column :business_statuses, :minimum_role_level, :integer, default: 999
    end
    
    unless column_exists?(:operation_types, :color)
      add_column :operation_types, :color, :string, default: 'primary'
    end
    
    unless column_exists?(:co_ownership_types, :minimum_role_level) 
      add_column :co_ownership_types, :minimum_role_level, :integer, default: 30
    end
  end
end
