# app/models/transaction_scenario.rb
class TransactionScenario < ApplicationRecord
  include AutoSluggable

  # ============================================================
  # CONSTANTES - Nombres canónicos de escenarios
  # Si un admin cambia el nombre en BD, actualizar aquí también.
  # Estos son los escenarios base del sistema.
  # ============================================================
  SCENARIOS = {
    venta_compra_directa:    'Venta por Compra Directa',
    venta_herencia:          'Venta por Herencia',
    venta_donacion:          'Venta por Donación',
    renta_local_comercial:   'Renta Local Comercial',
    renta_bodega_industrial: 'Renta Bodega Industrial',
    renta_apartamento:       'Renta Apartamento',
    renta_casa:              'Renta Casa Habitacional'
  }.freeze

  # ============================================================
  # RELACIONES
  # ============================================================
  has_many :scenario_documents, dependent: :destroy
  has_many :document_types, through: :scenario_documents
  has_many :business_transactions

  # ============================================================
  # VALIDACIONES
  # ============================================================
  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: {
    in: %w[compraventa renta_comercial renta_habitacional]
  }

  # ============================================================
  # SCOPES
  # ============================================================
  scope :active, -> { where(active: true) }
  scope :for_category, ->(category) { where(category: category) }

  # ============================================================
  # BÚSQUEDA SEGURA DE ESCENARIOS
  # Usa find_by + log de advertencia si no existe.
  # NO lanza excepción porque el admin puede no haber creado
  # todos los escenarios aún.
  # ============================================================
  SCENARIOS.each do |method_name, scenario_name|
    define_method("self.#{method_name}") do
      # No funciona con define_method para class methods
    end

    # Definir class methods dinámicamente
    singleton_class.define_method(method_name) do
      scenario = find_by(name: scenario_name)
      unless scenario
        Rails.logger.warn "⚠️ Escenario '#{scenario_name}' no encontrado en BD. " \
                          "Verificar seeds o crear desde panel admin."
      end
      scenario
    end
  end

  # ============================================================
  # MÉTODOS PARA DOCUMENTOS POR TIPO DE PARTICIPANTE
  # ============================================================

  # Documentos requeridos para un party_type específico
  def required_documents_for_party(party_type)
    scenario_documents.joins(:document_type)
                      .where(party_type: [party_type, 'ambos'], required: true)
                      .includes(:document_type)
  end

  def document_count_for_party(party_type)
    required_documents_for_party(party_type).count
  end

  # Documentos que SOLO aplican al copropietario principal
  # (inherentes a la transacción, no a la persona)
  def transaction_inherent_documents
    scenario_documents.joins(:document_type)
                      .where(party_type: 'copropietario_principal', required: true)
                      .includes(:document_type)
  end

  # Documentos que aplican a TODOS los copropietarios
  def shared_copropietario_documents
    scenario_documents.joins(:document_type)
                      .where(party_type: ['copropietario', 'ambos'], required: true)
                      .includes(:document_type)
  end

  # Resumen de documentos por party_type (útil para vista admin)
  def documents_summary
    scenario_documents.group(:party_type).count
  end
end
