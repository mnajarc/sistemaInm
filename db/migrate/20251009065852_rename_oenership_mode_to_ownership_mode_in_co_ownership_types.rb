class RenameOenershipModeToOwnershipModeInCoOwnershipTypes < ActiveRecord::Migration[8.0]
  def change
    rename_column :co_ownership_types, :oenership_mode, :ownership_mode
  end
end
