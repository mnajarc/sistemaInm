# app/models/document_type.rb
class DocumentType < ApplicationRecord
     include AutoSluggable
  belongs_to :replacement_document,
             class_name: 'DocumentType',
             optional: true,
             foreign_key: 'replacement_document_id'

  has_many :replaced_documents,
           class_name: 'DocumentType',
           foreign_key: 'replacement_document_id',
           dependent: :nullify

  has_many :document_requirements, dependent: :destroy
  has_many :document_validity_rules, dependent: :destroy
  has_many :property_documents, dependent: :destroy

  # Validaciones
  validates :name, presence: true, uniqueness: true, db_uniqueness: true
  validates :category, presence: true
  validates :valid_from, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validate  :valid_until_after_valid_from

  # Nota: display_name ya no es obligatorio, pero si está vacío,
  # el método display_name devolverá el name
  validates :requirement_context,
            inclusion: { in: %w[general person property acquisition contract],
                         allow_blank: true }

  # Scopes
  scope :current, -> {
    where('valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)', Date.current, Date.current)
  }

  scope :mandatory, -> { where(mandatory: true) }
  scope :blocking, -> { where(blocks_transaction: true) }
  scope :by_context, ->(context) { where(requirement_context: context) }
  scope :by_person_type, ->(type) { where(applies_to_person_type: type) }

  scope :ordered, -> { order(:position, :name) }

  # Validaciones
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Métodos personalizados
  def display_name
    super.presence || name
  end

  def long_description
    "#{display_name}: #{description}"
  end

  def valid_on?(date)
    valid_from <= date && (valid_until.nil? || valid_until >= date)
  end

  private

  def valid_until_after_valid_from
    return if valid_until.blank? || valid_from.blank?
    if valid_until < valid_from
      errors.add(:valid_until, 'debe ser posterior a valid_from')
    end
  end
end
