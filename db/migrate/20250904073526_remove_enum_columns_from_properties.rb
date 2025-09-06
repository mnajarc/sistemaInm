class RemoveEnumColumnsFromProperties < ActiveRecord::Migration[8.0]
  def change
    remove_column :properties, :property_type, :string
    remove_column :properties, :status, :string
  end
end
