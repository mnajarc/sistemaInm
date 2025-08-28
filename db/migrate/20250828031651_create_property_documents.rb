class CreatePropertyDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :property_documents do |t|
      t.references :property, null: false, foreign_key: true
      t.references :document_type, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.datetime :uploaded_at
      t.datetime :verified_at
      t.date :issued_at
      t.date :expires_at
      t.text :notes

      t.timestamps
    end
  end
end
