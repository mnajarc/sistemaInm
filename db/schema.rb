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

ActiveRecord::Schema[8.0].define(version: 2025_10_13_171934) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

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

  create_table "agent_transfers", force: :cascade do |t|
    t.bigint "business_transaction_id", null: false
    t.bigint "from_agent_id", null: false
    t.bigint "to_agent_id", null: false
    t.bigint "transferred_by_id", null: false
    t.text "reason", null: false
    t.datetime "transferred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_transaction_id", "transferred_at"], name: "idx_on_business_transaction_id_transferred_at_9ecb914154"
    t.index ["business_transaction_id"], name: "index_agent_transfers_on_business_transaction_id"
    t.index ["from_agent_id"], name: "index_agent_transfers_on_from_agent_id"
    t.index ["to_agent_id"], name: "index_agent_transfers_on_to_agent_id"
    t.index ["transferred_by_id"], name: "index_agent_transfers_on_transferred_by_id"
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

  create_table "business_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.string "color", default: "secondary"
    t.boolean "active", default: true
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.integer "minimum_role_level", default: 999
    t.index ["active"], name: "index_business_statuses_on_active"
    t.index ["metadata"], name: "index_business_statuses_on_metadata", using: :gin
    t.index ["name"], name: "index_business_statuses_on_name", unique: true
    t.index ["sort_order"], name: "index_business_statuses_on_sort_order"
  end

  create_table "business_transaction_co_owners", force: :cascade do |t|
    t.bigint "business_transaction_id", null: false
    t.bigint "client_id"
    t.string "person_name"
    t.decimal "percentage", precision: 5, scale: 2
    t.string "role"
    t.boolean "deceased", default: false, null: false
    t.text "inheritance_case_notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_transaction_id", "active"], name: "idx_co_owners_transaction_active"
    t.index ["business_transaction_id"], name: "idx_on_business_transaction_id_2d9fea40bb"
    t.index ["client_id"], name: "index_business_transaction_co_owners_on_client_id"
  end

  create_table "business_transactions", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "operation_type_id", null: false
    t.bigint "business_status_id", null: false
    t.bigint "offering_client_id", null: false
    t.bigint "acquiring_client_id"
    t.date "start_date", null: false
    t.date "estimated_completion_date"
    t.date "actual_completion_date"
    t.decimal "price", precision: 15, scale: 2, null: false
    t.decimal "commission_percentage", precision: 5, scale: 2, default: "0.0"
    t.text "notes"
    t.text "terms_and_conditions"
    t.boolean "is_primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "listing_agent_id", null: false
    t.bigint "current_agent_id", null: false
    t.bigint "selling_agent_id"
    t.bigint "co_ownership_type_id"
    t.string "external_operation_number"
    t.string "contract_signer_type"
    t.string "c21_legal_representative"
    t.integer "contract_days_term"
    t.date "contract_expiration_date"
    t.string "celebration_place"
    t.decimal "commission_amount", precision: 15, scale: 2
    t.decimal "commission_vat", precision: 15, scale: 2
    t.decimal "recommended_price", precision: 15, scale: 2
    t.string "payment_method"
    t.string "deed_number"
    t.date "deed_date"
    t.string "notary_number"
    t.string "notary_name"
    t.string "notary_location"
    t.string "real_folio"
    t.string "property_registry_location"
    t.date "registration_date"
    t.string "acquisition_legal_act"
    t.date "acquisition_date"
    t.boolean "is_mortgaged_at_transaction", default: false
    t.boolean "has_liens_at_transaction", default: false
    t.index ["acquiring_client_id"], name: "index_business_transactions_on_acquiring_client_id"
    t.index ["acquisition_legal_act"], name: "index_business_transactions_on_acquisition_legal_act"
    t.index ["business_status_id"], name: "index_business_transactions_on_business_status_id"
    t.index ["co_ownership_type_id"], name: "index_business_transactions_on_co_ownership_type_id"
    t.index ["contract_expiration_date"], name: "index_business_transactions_on_contract_expiration_date"
    t.index ["current_agent_id"], name: "index_business_transactions_on_current_agent_id"
    t.index ["deed_number"], name: "index_business_transactions_on_deed_number"
    t.index ["external_operation_number"], name: "index_business_transactions_on_external_operation_number", unique: true
    t.index ["is_mortgaged_at_transaction"], name: "index_business_transactions_on_is_mortgaged_at_transaction"
    t.index ["listing_agent_id"], name: "index_business_transactions_on_listing_agent_id"
    t.index ["offering_client_id"], name: "index_business_transactions_on_offering_client_id"
    t.index ["operation_type_id"], name: "index_business_transactions_on_operation_type_id"
    t.index ["property_id", "is_primary"], name: "index_business_transactions_on_property_id_and_is_primary"
    t.index ["property_id"], name: "index_business_transactions_on_property_id"
    t.index ["real_folio"], name: "index_business_transactions_on_real_folio"
    t.index ["selling_agent_id"], name: "index_business_transactions_on_selling_agent_id"
    t.index ["start_date"], name: "index_business_transactions_on_start_date"
  end

  create_table "civil_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_civil_statuses_on_active"
    t.index ["name"], name: "index_civil_statuses_on_name", unique: true
    t.index ["sort_order"], name: "index_civil_statuses_on_sort_order"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.boolean "active", default: true
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "co_ownership_roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.index ["active"], name: "index_co_ownership_roles_on_active"
    t.index ["metadata"], name: "index_co_ownership_roles_on_metadata", using: :gin
    t.index ["name"], name: "index_co_ownership_roles_on_name", unique: true
    t.index ["sort_order"], name: "index_co_ownership_roles_on_sort_order"
  end

  create_table "co_ownership_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.integer "sort_order", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.integer "minimum_role_level", default: 30
    t.string "ownership_mode", default: "único", null: false
    t.index ["active"], name: "index_co_ownership_types_on_active"
    t.index ["metadata"], name: "index_co_ownership_types_on_metadata", using: :gin
    t.index ["name"], name: "index_co_ownership_types_on_name", unique: true
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

  create_table "contract_signer_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.boolean "requires_power_of_attorney", default: false, null: false
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_contract_signer_types_on_active"
    t.index ["name"], name: "index_contract_signer_types_on_name", unique: true
    t.index ["requires_power_of_attorney"], name: "index_contract_signer_types_on_requires_power_of_attorney"
    t.index ["sort_order"], name: "index_contract_signer_types_on_sort_order"
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
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.string "requirement_context", default: "general"
    t.string "applies_to_person_type"
    t.string "applies_to_acquisition_type"
    t.boolean "mandatory", default: false
    t.boolean "blocks_transaction", default: false
    t.index ["applies_to_person_type"], name: "index_document_types_on_applies_to_person_type"
    t.index ["blocks_transaction"], name: "index_document_types_on_blocks_transaction"
    t.index ["mandatory"], name: "index_document_types_on_mandatory"
    t.index ["metadata"], name: "index_document_types_on_metadata", using: :gin
    t.index ["name"], name: "index_document_types_on_name", unique: true
    t.index ["requirement_context"], name: "index_document_types_on_requirement_context"
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

  create_table "financial_institutions", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "institution_type"
    t.string "code"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_financial_institutions_on_active"
    t.index ["code"], name: "index_financial_institutions_on_code"
    t.index ["institution_type"], name: "index_financial_institutions_on_institution_type"
    t.index ["name"], name: "index_financial_institutions_on_name", unique: true
  end

  create_table "identification_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.string "issuing_authority"
    t.integer "validity_years"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_identification_types_on_active"
    t.index ["name"], name: "index_identification_types_on_name", unique: true
    t.index ["sort_order"], name: "index_identification_types_on_sort_order"
  end

  create_table "legal_acts", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.string "category"
    t.boolean "requires_notary", default: true, null: false
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_legal_acts_on_active"
    t.index ["category"], name: "index_legal_acts_on_category"
    t.index ["name"], name: "index_legal_acts_on_name", unique: true
    t.index ["sort_order"], name: "index_legal_acts_on_sort_order"
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.string "path"
    t.string "icon"
    t.integer "parent_id"
    t.integer "sort_order", default: 0
    t.integer "minimum_role_level", default: 999
    t.boolean "active", default: true
    t.boolean "system_menu", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["minimum_role_level"], name: "index_menu_items_on_minimum_role_level"
    t.index ["name"], name: "index_menu_items_on_name", unique: true
    t.index ["parent_id"], name: "index_menu_items_on_parent_id"
    t.index ["sort_order"], name: "index_menu_items_on_sort_order"
  end

  create_table "mexican_states", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", limit: 5, null: false
    t.string "full_name", null: false
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_mexican_states_on_active"
    t.index ["code"], name: "index_mexican_states_on_code", unique: true
    t.index ["name"], name: "index_mexican_states_on_name", unique: true
  end

  create_table "offer_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status_code", null: false
    t.string "display_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status_code"], name: "index_offer_statuses_on_status_code", unique: true
  end

  create_table "offers", force: :cascade do |t|
    t.bigint "business_transaction_id", null: false
    t.bigint "offerer_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "offer_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "valid_until"
    t.text "terms"
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.integer "queue_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "offer_status_id", null: false
    t.index ["business_transaction_id", "queue_position"], name: "index_offers_on_business_transaction_id_and_queue_position"
    t.index ["business_transaction_id", "status"], name: "index_offers_on_business_transaction_id_and_status"
    t.index ["business_transaction_id"], name: "index_offers_on_business_transaction_id"
    t.index ["offer_status_id"], name: "index_offers_on_offer_status_id"
    t.index ["offerer_id", "status"], name: "index_offers_on_offerer_id_and_status"
    t.index ["offerer_id"], name: "index_offers_on_offerer_id"
  end

  create_table "operation_types", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.text "description"
    t.boolean "active"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.string "color", default: "primary"
    t.index ["metadata"], name: "index_operation_types_on_metadata", using: :gin
    t.index ["name"], name: "index_operation_types_on_name", unique: true
  end

  create_table "person_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.string "tax_regime"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_person_types_on_active"
    t.index ["name"], name: "index_person_types_on_name", unique: true
    t.index ["sort_order"], name: "index_person_types_on_sort_order"
  end

  create_table "properties", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "price", precision: 15, scale: 2
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
    t.bigint "property_type_id", null: false
    t.integer "parking_spaces"
    t.boolean "furnished"
    t.boolean "pets_allowed"
    t.boolean "elevator"
    t.boolean "balcony"
    t.boolean "terrace"
    t.boolean "garden"
    t.boolean "pool"
    t.boolean "security"
    t.boolean "gym"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "contact_phone"
    t.string "contact_email"
    t.text "internal_notes"
    t.date "available_from"
    t.datetime "published_at"
    t.bigint "co_ownership_type_id"
    t.text "co_owners_details"
    t.json "co_ownership_percentage"
    t.string "street"
    t.string "exterior_number"
    t.string "interior_number"
    t.string "neighborhood"
    t.string "municipality"
    t.string "country", default: "México"
    t.boolean "has_extensions", default: false
    t.string "land_use"
    t.index ["available_from"], name: "index_properties_on_available_from"
    t.index ["city", "state", "municipality"], name: "index_properties_location"
    t.index ["co_ownership_type_id"], name: "index_properties_on_co_ownership_type_id"
    t.index ["land_use"], name: "index_properties_on_land_use"
    t.index ["latitude", "longitude"], name: "index_properties_on_coordinates"
    t.index ["municipality"], name: "index_properties_on_municipality"
    t.index ["neighborhood"], name: "index_properties_on_neighborhood"
    t.index ["parking_spaces"], name: "index_properties_on_parking_spaces"
    t.index ["price"], name: "index_properties_on_price"
    t.index ["property_type_id"], name: "index_properties_on_property_type_id"
    t.index ["published_at"], name: "index_properties_on_published_at"
    t.index ["street"], name: "index_properties_on_street"
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

  create_table "property_statuses", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.text "description"
    t.string "color"
    t.boolean "is_available"
    t.boolean "active"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.index ["metadata"], name: "index_property_statuses_on_metadata", using: :gin
    t.index ["name"], name: "index_property_statuses_on_name", unique: true
  end

  create_table "property_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.index ["active"], name: "index_property_types_on_active"
    t.index ["metadata"], name: "index_property_types_on_metadata", using: :gin
    t.index ["name"], name: "index_property_types_on_name", unique: true
    t.index ["sort_order"], name: "index_property_types_on_sort_order"
  end

  create_table "role_change_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "old_role"
    t.integer "new_role"
    t.datetime "changed_at", precision: nil, null: false
    t.string "changed_by_ip"
    t.text "notes"
    t.index ["user_id"], name: "index_role_change_logs_on_user_id"
  end

  create_table "role_menu_permissions", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "menu_item_id", null: false
    t.boolean "can_view", default: true
    t.boolean "can_edit", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_role_menu_permissions_on_menu_item_id"
    t.index ["role_id", "menu_item_id"], name: "idx_role_menu_unique", unique: true
    t.index ["role_id"], name: "index_role_menu_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.text "description"
    t.integer "level", default: 999, null: false
    t.boolean "active", default: true
    t.boolean "system_role", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "icon"
    t.index ["level"], name: "index_roles_on_level"
    t.index ["metadata"], name: "index_roles_on_metadata", using: :gin
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "system_configurations", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.string "value_type", default: "string", null: false
    t.string "category", null: false
    t.text "description", null: false
    t.boolean "active", default: true, null: false
    t.boolean "system_config", default: false, null: false
    t.json "environments"
    t.json "metadata"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_system_configurations_on_active"
    t.index ["category"], name: "index_system_configurations_on_category"
    t.index ["key"], name: "index_system_configurations_on_key", unique: true
    t.index ["system_config"], name: "index_system_configurations_on_system_config"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.bigint "role_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_transfers", "business_transactions"
  add_foreign_key "agent_transfers", "users", column: "from_agent_id"
  add_foreign_key "agent_transfers", "users", column: "to_agent_id"
  add_foreign_key "agent_transfers", "users", column: "transferred_by_id"
  add_foreign_key "agents", "users"
  add_foreign_key "business_transaction_co_owners", "business_transactions"
  add_foreign_key "business_transaction_co_owners", "clients"
  add_foreign_key "business_transactions", "business_statuses"
  add_foreign_key "business_transactions", "clients", column: "acquiring_client_id"
  add_foreign_key "business_transactions", "clients", column: "offering_client_id"
  add_foreign_key "business_transactions", "co_ownership_types"
  add_foreign_key "business_transactions", "operation_types"
  add_foreign_key "business_transactions", "properties"
  add_foreign_key "business_transactions", "users", column: "current_agent_id"
  add_foreign_key "business_transactions", "users", column: "listing_agent_id"
  add_foreign_key "business_transactions", "users", column: "selling_agent_id"
  add_foreign_key "clients", "users"
  add_foreign_key "commissions", "agents"
  add_foreign_key "commissions", "properties"
  add_foreign_key "contracts", "clients"
  add_foreign_key "contracts", "properties"
  add_foreign_key "document_requirements", "document_types"
  add_foreign_key "document_validity_rules", "document_types"
  add_foreign_key "menu_items", "menu_items", column: "parent_id"
  add_foreign_key "offers", "business_transactions"
  add_foreign_key "offers", "clients", column: "offerer_id"
  add_foreign_key "offers", "offer_statuses"
  add_foreign_key "properties", "co_ownership_types"
  add_foreign_key "properties", "property_types"
  add_foreign_key "properties", "users"
  add_foreign_key "property_documents", "document_types"
  add_foreign_key "property_documents", "properties"
  add_foreign_key "property_documents", "users"
  add_foreign_key "property_exclusivities", "agents"
  add_foreign_key "property_exclusivities", "properties"
  add_foreign_key "role_change_logs", "users"
  add_foreign_key "role_menu_permissions", "menu_items"
  add_foreign_key "role_menu_permissions", "roles"
  add_foreign_key "users", "roles"
end
