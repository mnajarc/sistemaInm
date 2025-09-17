class AddCoOwnershipToProperties < ActiveRecord::Migration[8.0]
  def change
    add_reference :properties, :co_ownership_type, null: true, foreign_key: true
    add_column :properties, :co_owners_details, :text
    add_column :properties, :co_ownership_percentage, :json # Para múltiples porcentajes
  end
end
