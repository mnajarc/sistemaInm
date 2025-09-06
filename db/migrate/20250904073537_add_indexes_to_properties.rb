class AddIndexesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_index :properties, :published_at
    add_index :properties, :available_from
    add_index :properties, [:latitude, :longitude], name: 'index_properties_on_coordinates'
    add_index :properties, :parking_spaces
    add_index :properties, :price
    add_index :properties, [:property_type_id, :property_status_id], name: 'index_properties_on_type_status'
  end
end
