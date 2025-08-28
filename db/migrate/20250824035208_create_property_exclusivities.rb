class CreatePropertyExclusivities < ActiveRecord::Migration[8.0]
  def change
    create_table :property_exclusivities do |t|
      t.references :property, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :commission_percentage, precision: 15, scale: 2
      t.boolean :is_active

      t.timestamps
    end
  end
end
