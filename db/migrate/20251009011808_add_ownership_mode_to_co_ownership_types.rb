class AddOwnershipModeToCoOwnershipTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :co_ownership_types, :oenership_mode, :string, null: false, default: "único"
  end
end
