# db/migrate/XXXXX_create_instance_config.rb
class CreateInstanceConfig < ActiveRecord::Migration[8.0]
  def change
    create_table :instance_config do |t|
      t.string :app_name, default: "inmobInteligeria"
      t.string :app_logo
      t.string :app_primary_color, default: "#007bff"
      t.string :app_favicon
      t.string :app_tagline
      t.string :instance_name  # Nombre interno de la instancia
      t.string :organization_name  # Empresa propietaria
      t.boolean :allow_external_access, default: false  # Para VPN/privada
      t.string :admin_email  # Contacto admin de la instancia
      
      t.timestamps
    end
    
    # Un solo registro por instancia
    add_index :instance_config, :instance_name, unique: true
  end
end