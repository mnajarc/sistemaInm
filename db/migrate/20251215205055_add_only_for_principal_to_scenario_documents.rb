# db/migrate/TIMESTAMP_add_only_for_principal_to_scenario_documents.rb
class AddOnlyForPrincipalToScenarioDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :scenario_documents, :only_for_principal, :boolean, default: false
    add_index :scenario_documents, :only_for_principal
  end
end