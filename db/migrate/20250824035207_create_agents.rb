class CreateAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :agents do |t|
      t.string :license_number
      t.string :phone
      t.text :specialties
      t.decimal :commission_rate, precision: 5, scale: 2
      t.boolean :is_active
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
