class AddUserToClients < ActiveRecord::Migration[8.0]
  def change
    add_reference :clients, :user, null: true, foreign_key: true
    add_column :clients, :active, :boolean, default: true
    add_index :clients, :email, unique: true
  end
end
