class AddRoleReferenceToUsers < ActiveRecord::Migration[8.0]
  def up
    add_reference :users, :role, foreign_key: true, index: true

    # Poblar role_id desde enum role
    say_with_time "Backfilling users.role_id from users.role enum" do
      Role.reset_column_information
      User.reset_column_information

      User.find_each do |user|
        # Enum guarda el nombre como string en column 'role'
        role_name = user.role
        db_role = Role.find_by(name: role_name)
        if db_role
          user.update_column(:role_id, db_role.id)
        end
      end
    end

    # Opcional: eliminar la columna enum role
    remove_column :users, :role, :integer
  end

  def down
    # Re-agregar enum column
    add_column :users, :role, :integer, default: 0, null: false

    # Repoblar enum desde role_id
    say_with_time "Repopulating users.role enum from users.role_id" do
      User.find_each do |user|
        db_role = Role.find_by(id: user.role_id)
        user.update_column(:role, Role.roles[db_role.name]) if db_role
      end
    end

    remove_reference :users, :role, foreign_key: true
  end
end
