module CatalogConfigurable
  extend ActiveSupport::Concern
  
  included do
    # Campos comunes para catálogos
    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true
    validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
    
    scope :active, -> { where(active: true) }
    scope :by_sort_order, -> { order(:sort_order) }
    scope :for_display, -> { active.by_sort_order }
    
    # Metadatos como JSON para configuraciones adicionales
    def metadata_for(key, default = nil)
      return default unless metadata.present?
      metadata[key.to_s] || default
    end
    
    def set_metadata(key, value)
      self.metadata ||= {}
      self.metadata[key.to_s] = value
    end
    
    # Color con fallback configurable
    def display_color
      return color if color.present?
      self.class.default_color
    end
    
    # Icono con fallback configurable  
    def display_icon
      return icon if icon.present?
      self.class.default_icon
    end
  end
  
  class_methods do
    def default_color
      SystemConfiguration.get("#{model_name.param_key}.default_color", 'secondary')
    end
    
    def default_icon
      SystemConfiguration.get("#{model_name.param_key}.default_icon", 'bi-circle')
    end
    
    def create_with_metadata(attributes)
      metadata = attributes.delete(:metadata) || {}
      record = create!(attributes)
      metadata.each { |key, value| record.set_metadata(key, value) }
      record.save! if record.metadata_changed?
      record
    end
  end
end
