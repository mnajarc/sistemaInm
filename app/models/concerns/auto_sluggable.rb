# app/models/concerns/auto_sluggable.rb
# Concern reutilizable para auto-generar identificadores (name) a partir de display_name

module AutoSluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_name_from_display_name, on: :create
  end

  private

  # Auto-genera name a partir de display_name
  # Solo funciona en CREATE, no modifica registros existentes
  def generate_name_from_display_name
    return if name.present?           # Si ya tiene name, no hacer nada
    return unless display_name.present? # Si no tiene display_name, saltar

    self.name = slugify(display_name)
  end

  # Convierte texto a formato slug válido para 'name'
  # Ejemplo: "Identificación Oficial (INE/IFE)" → "identificacion_oficial_ine_ife"
  def slugify(text)
    text
      .unicode_normalize(:nfd)           # Normalizar Unicode
      .gsub(/[\u0300-\u036f]/, '')       # Quitar marcas diacríticas (acentos)
      .downcase                           # Convertir a minúsculas
      .strip                              # Quitar espacios al inicio/final
      .gsub(/[^a-z0-9\s-]/, '')          # Solo alfanuméricos, espacios, guiones
      .gsub(/\s+/, '_')                  # Espacios → guiones bajos
      .gsub(/_+/, '_')                   # Múltiples guiones bajos → uno solo
  end
end