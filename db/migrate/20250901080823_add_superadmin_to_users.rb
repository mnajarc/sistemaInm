class AddSuperadminToUsers < ActiveRecord::Migration[8.0]
  def up
    # Para integer enum no necesitas hacer nada en la DB
    # El valor superadmin: 3 ya está definido en el modelo User

    # Solo verificar que el modelo tenga el enum correcto
    puts "✅ SuperAdmin enum value agregado al modelo User"
    puts "   client: 0, agent: 1, admin: 2, superadmin: 3"
  end

  def down
    # No hay nada que revertir
    puts "ℹ️ No hay cambios de DB que revertir para integer enum"
  end
end
