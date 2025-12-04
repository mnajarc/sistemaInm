# app/models/co_ownership_link.rb
# NUEVO: Vínculo entre cliente principal y copropietarios
class CoOwnershipLink < ApplicationRecord
  # ═══════════════════════════════════════════════════════════
  # RELACIONES
  # ═══════════════════════════════════════════════════════════
  belongs_to :primary_client, class_name: 'Client', foreign_key: 'primary_client_id'
  belongs_to :co_owner_client, class_name: 'Client', foreign_key: 'co_owner_client_id'
  belongs_to :initial_contact_form, optional: true
  belongs_to :business_transaction, optional: true
  
  # ═══════════════════════════════════════════════════════════
  # VALIDACIONES
  # ═══════════════════════════════════════════════════════════
  validates :primary_client_id, :co_owner_client_id, presence: true
  validates :ownership_percentage, presence: true, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 100 
  }
  
  # No permitir vínculo consigo mismo
  validate :primary_and_co_owner_different
  
  # ═══════════════════════════════════════════════════════════
  # CALLBACKS
  # ═══════════════════════════════════════════════════════════
  before_save :generate_co_owner_opportunity_id
  
  # ═══════════════════════════════════════════════════════════
  # MÉTODOS
  # ═══════════════════════════════════════════════════════════
  
  # Generar identificador temporal para copropietario
  def generate_co_owner_opportunity_id
    return if co_owner_opportunity_id.present?
    
    # Formato: CP-APELLIDO-FECHA-SECUENCIA
    # Ejemplo: CP-GARCIA-20251130-001
    
    co_owner_name = co_owner_client.name
    name_parts = co_owner_name.split(/\s+/)
    last_name = name_parts.length >= 2 ? name_parts[1] : name_parts[0]
    
    last_name_clean = I18n.transliterate(last_name.to_s)
      .gsub(/[^a-zA-Z0-9]/, '')
      .upcase
      .slice(0, 10)
    
    date_str = Date.current.strftime('%Y%m%d')
    base_id = "CP-#{last_name_clean}-#{date_str}"
    
    # Verificar unicidad
    counter = 1
    id_candidate = base_id
    
    while CoOwnershipLink.where.not(id: id)
                         .exists?(co_owner_opportunity_id: id_candidate)
      id_candidate = "#{base_id}-#{counter.to_s.rjust(3, '0')}"
      counter += 1
    end
    
    self.co_owner_opportunity_id = id_candidate
    Rails.logger.info "👥 Co-owner Opportunity ID: #{co_owner_opportunity_id}"
  end
  
  private
  
  def primary_and_co_owner_different
    if primary_client_id == co_owner_client_id
      errors.add(:base, "Un cliente no puede ser copropietario de sí mismo")
    end
  end
end
