# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_28_204059) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.string "license_number"
    t.string "phone"
    t.text "specialties"
    t.decimal "commission_rate", precision: 5, scale: 2
    t.boolean "is_active"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_agents_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "commissions", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "agent_id", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.string "commission_type"
    t.string "status"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_commissions_on_agent_id"
    t.index ["property_id"], name: "index_commissions_on_property_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "property_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["property_id"], name: "index_contracts_on_property_id"
  end

  create_table "document_requirements", force: :cascade do |t|
    t.bigint "document_type_id", null: false
    t.string "property_type", null: false
    t.string "transaction_type", null: false
    t.string "client_type", null: false
    t.string "person_type", null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.boolean "is_required", null: false
    t.string "applies_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type_id"], name: "index_document_requirements_on_document_type_id"
  end

  create_table "document_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "category", null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.integer "replacement_document_id"
    t.boolean "is_active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_document_types_on_name", unique: true
    t.check_constraint "valid_until IS NULL OR valid_until > valid_from", name: "valid_until_after_valid_from"
  end

  create_table "document_validity_rules", force: :cascade do |t|
    t.bigint "document_type_id", null: false
    t.integer "validity_period_months", null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.boolean "is_active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type_id"], name: "index_document_validity_rules_on_document_type_id"
    t.check_constraint "validity_period_months > 0", name: "validity_period_positive"
  end

  create_table "properties", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "price", precision: 15, scale: 2
    t.string "property_type"
    t.string "status"
    t.text "address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.integer "bedrooms"
    t.integer "bathrooms"
    t.decimal "built_area_m2", precision: 10, scale: 2
    t.decimal "lot_area_m2", precision: 10, scale: 2
    t.integer "year_built"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_documents", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "document_type_id", null: false
    t.bigint "user_id", null: false
    t.string "status", null: false
    t.datetime "uploaded_at", null: false
    t.datetime "verified_at"
    t.date "issued_at", null: false
    t.date "expires_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type_id"], name: "index_property_documents_on_document_type_id"
    t.index ["property_id"], name: "index_property_documents_on_property_id"
    t.index ["user_id"], name: "index_property_documents_on_user_id"
  end

  create_table "property_exclusivities", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "agent_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "commission_percentage", precision: 15, scale: 2
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_property_exclusivities_on_agent_id"
    t.index ["property_id"], name: "index_property_exclusivities_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agents", "users"
  add_foreign_key "commissions", "agents"
  add_foreign_key "commissions", "properties"
  add_foreign_key "contracts", "clients"
  add_foreign_key "contracts", "properties"
  add_foreign_key "document_requirements", "document_types"
  add_foreign_key "document_validity_rules", "document_types"
  add_foreign_key "properties", "users"
  add_foreign_key "property_documents", "document_types"
  add_foreign_key "property_documents", "properties"
  add_foreign_key "property_documents", "users"
  add_foreign_key "property_exclusivities", "agents"
  add_foreign_key "property_exclusivities", "properties"
end
