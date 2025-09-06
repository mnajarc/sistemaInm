class AddReferencesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_reference :properties, :property_type, null: false, foreign_key: true
    add_reference :properties, :property_status, null: false, foreign_key: true
    add_reference :properties, :operation_type, null: false, foreign_key: true
    add_column :properties, :parking_spaces, :integer
    add_column :properties, :furnished, :boolean
    add_column :properties, :pets_allowed, :boolean
    add_column :properties, :elevator, :boolean
    add_column :properties, :balcony, :boolean
    add_column :properties, :terrace, :boolean
    add_column :properties, :garden, :boolean
    add_column :properties, :pool, :boolean
    add_column :properties, :security, :boolean
    add_column :properties, :gym, :boolean
    add_column :properties, :latitude, :decimal
    add_column :properties, :longitude, :decimal
    add_column :properties, :contact_phone, :string
    add_column :properties, :contact_email, :string
    add_column :properties, :internal_notes, :text
    add_column :properties, :available_from, :date
    add_column :properties, :published_at, :datetime
  end
end
