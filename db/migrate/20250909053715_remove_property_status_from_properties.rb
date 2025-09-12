class RemovePropertyStatusFromProperties < ActiveRecord::Migration[8.0]
  def change
    remove_reference :properties, :property_status, null: false, foreign_key: true
  end
end
