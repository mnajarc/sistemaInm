class SystemConfiguration < ApplicationRecord
  # Validaciones
  validates :key, presence: true, uniqueness: true
  validates :value_type, presence: true, inclusion: { 
    in: %w[string integer decimal boolean array hash] 
  }
  validates :category, presence: true
  validates :description, presence: true
  
  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :active, -> { where(active: true) }
  scope :for_environment, ->(env) { 
    where('environments IS NULL OR environments @> ?', [env].to_json) 
  }
  
  # Métodos de clase para obtener configuraciones
  def self.get(key, default = nil)
    config = active.find_by(key: key)
    return default unless config
    config.parsed_value
  end
  
  def self.set(key, value, description = nil)
    config = find_or_initialize_by(key: key)
    config.value = value.to_s
    config.value_type = detect_type(value)
    config.description = description if description
    config.save!
    config
  end
  
  def self.category_hash(category)
    by_category(category).active.pluck(:key, :parsed_value).to_h
  end
  
  # Instancia: valor parseado según tipo
  def parsed_value
    case value_type
    when 'string' then value
    when 'integer' then value.to_i
    when 'decimal' then BigDecimal(value)
    when 'boolean' then ActiveModel::Type::Boolean.new.cast(value)
    when 'array' then JSON.parse(value)
    when 'hash' then JSON.parse(value)
    else value
    end
  rescue JSON::ParserError
    value
  end
  
  def parsed_value=(new_value)
    self.value = new_value.to_s
    self.value_type = self.class.detect_type(new_value)
  end
  
  private
  
  def self.detect_type(value)
    case value
    when String then 'string'
    when Integer then 'integer'
    when BigDecimal, Float then 'decimal'
    when TrueClass, FalseClass then 'boolean'
    when Array then 'array'
    when Hash then 'hash'
    else 'string'
    end
  end
end