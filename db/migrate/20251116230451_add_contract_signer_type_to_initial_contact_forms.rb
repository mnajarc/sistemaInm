class AddContractSignerTypeToInitialContactForms < ActiveRecord::Migration[8.0]
  def change
    add_reference :initial_contact_forms, :contract_signer_type, null: true, foreign_key: true
  end
end
