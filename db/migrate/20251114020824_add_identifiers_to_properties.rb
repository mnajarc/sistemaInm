
class AddIdentifiersToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :human_readable_identifier, :string
    add_index :properties, :human_readable_identifier, unique: true
    
    add_reference :properties, :land_use_type, foreign_key: true, null: true
  end
end

