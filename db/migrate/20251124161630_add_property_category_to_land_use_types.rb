# db/migrate/20251124161630_add_property_category_to_land_use_types.rb
class AddPropertyCategoryToLandUseTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :land_use_types, :property_category, :string
    
    # Valores por defecto según mapping actual
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE land_use_types 
          SET property_category = CASE code
            WHEN 'HAB' THEN 'habitacional'
            WHEN 'HAB_UNI' THEN 'habitacional'
            WHEN 'HAB_PLURI' THEN 'habitacional'
            WHEN 'HAB_MIX' THEN 'mixto'
            WHEN 'COM' THEN 'comercial'
            WHEN 'COM_LOCAL' THEN 'comercial'
            WHEN 'COM_CENTRO' THEN 'comercial'
            WHEN 'COM_OFICINA' THEN 'comercial'
            WHEN 'COM_SERVICIOS' THEN 'comercial'
            WHEN 'IND' THEN 'industrial'
            WHEN 'MIX' THEN 'mixto'
            WHEN 'AGR' THEN 'otros'
            ELSE 'otros'
          END
        SQL
        
        # Hacer que sea obligatorio después de asignar valores
        change_column_null :land_use_types, :property_category, false
      end
    end
  end
end
