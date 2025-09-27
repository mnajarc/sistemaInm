class DocumentType < ApplicationRecord
  belongs_to :replacement_document,
             class_name: "DocumentType",
             optional: true,
             foreign_key: "replacement_document_id"
  has_many   :replaced_documents,
             class_name: "DocumentType",
             foreign_key: "replacement_document_id",
             dependent: :nullify
  has_many   :document_requirements, dependent: :destroy
  has_many   :document_validity_rules, dependent: :destroy
  has_many   :property_documents, dependent: :destroy

  # Validaciones Rails + DB
  validates :name, presence: true, uniqueness: true, db_uniqueness: true
  validates :category, presence: true
  validates :valid_from, presence: true
  validates :is_active, inclusion: { in: [ true, false ] }
  validate  :valid_until_after_valid_from

  scope :current, -> {
    where("valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)", Date.current, Date.current)
  }

  def valid_on?(date)
    valid_from <= date && (valid_until.nil? || valid_until >= date)
  end

  private

  def valid_until_after_valid_from
    return if valid_until.blank? || valid_from.blank?
    errors.add(:valid_until, "debe ser posterior a valid_from") if valid_until < valid_from
  end
end
