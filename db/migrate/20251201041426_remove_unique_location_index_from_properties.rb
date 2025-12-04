class RemoveUniqueLocationIndexFromProperties < ActiveRecord::Migration[8.0]
def change
remove_index :properties, name: :idx_properties_unique_location
end
end

