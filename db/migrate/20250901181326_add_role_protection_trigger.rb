class AddRoleProtectionTrigger < ActiveRecord::Migration[8.0]
  def up
    # ✅ Crear función de protección
    execute <<-SQL
      CREATE OR REPLACE FUNCTION prevent_role_escalation()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Prevenir que alguien se auto-asigne superadmin directamente en la DB
        IF NEW.role = 2 AND OLD.role != 2 THEN  -- 2 = superadmin en el enum
          RAISE EXCEPTION 'Cambio directo a SuperAdmin no permitido. Use la aplicación.';
        END IF;
      #{'  '}
        -- Log del cambio para auditoría
        INSERT INTO role_change_logs (user_id, old_role, new_role, changed_at)
        VALUES (NEW.id, OLD.role, NEW.role, NOW());
      #{'  '}
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # ✅ Crear tabla de logs de cambios de rol
    create_table :role_change_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :old_role
      t.integer :new_role
      t.timestamp :changed_at, null: false
      t.string :changed_by_ip
      t.text :notes
    end

    # ✅ Crear trigger
    execute <<-SQL
      CREATE TRIGGER role_protection_trigger
      BEFORE UPDATE OF role ON users
      FOR EACH ROW
      WHEN (OLD.role IS DISTINCT FROM NEW.role)
      EXECUTE FUNCTION prevent_role_escalation();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS role_protection_trigger ON users;"
    execute "DROP FUNCTION IF EXISTS prevent_role_escalation();"
    drop_table :role_change_logs
  end
end
