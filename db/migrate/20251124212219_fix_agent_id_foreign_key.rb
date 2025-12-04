
# db/migrate/XXXXXX_fix_agent_id_foreign_key.rb
class FixAgentIdForeignKey < ActiveRecord::Migration[8.0]
  def up
    # Remover constraint incorrecta
    remove_foreign_key :initial_contact_forms, column: :agent_id, to_table: :users
    
    # Agregar constraint correcta
    add_foreign_key :initial_contact_forms, :agents, column: :agent_id
  end
  
  def down
    remove_foreign_key :initial_contact_forms, column: :agent_id, to_table: :agents
    add_foreign_key :initial_contact_forms, :users, column: :agent_id
  end
end
