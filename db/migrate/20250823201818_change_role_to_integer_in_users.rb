class ChangeRoleToIntegerInUsers < ActiveRecord::Migration[8.0]
  def up
    # Cambiar de VARCHAR a INTEGER
    change_column :users, :role, :integer, using: 'role::integer'
  end

  def down
    change_column :users, :role, :string
  end
end
