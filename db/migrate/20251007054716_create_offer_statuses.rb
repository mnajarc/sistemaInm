class CreateOfferStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :offer_statuses do |t|
      t.string  :name, null: false
      t.integer :status_code, null: false
      t.string  :display_name, null: false

      t.timestamps
    end
    add_index :offer_statuses, :status_code, unique: true
  end
end
