class RemoveRoleProtectionTrigger < ActiveRecord::Migration[8.0]
  def up
    # Eliminar trigger problemático
    execute "DROP TRIGGER IF EXISTS role_protection_trigger ON users;"
    execute "DROP FUNCTION IF EXISTS prevent_role_escalation();"

    # Mantener solo la tabla de logs si existe
    # drop_table :role_change_logs if table_exists?(:role_change_logs)
  end

  def down
    # No recrear el trigger problemático
    puts "Trigger no será recreado - usar protecciones de aplicación"
  end
end
