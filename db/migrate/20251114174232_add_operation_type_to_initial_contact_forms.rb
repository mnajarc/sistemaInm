class AddOperationTypeToInitialContactForms < ActiveRecord::Migration[8.0]
  def change
    add_reference :initial_contact_forms, :operation_type, foreign_key: true, null: true
  end
end
