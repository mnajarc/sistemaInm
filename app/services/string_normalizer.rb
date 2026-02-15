# app/services/string_normalizer.rb
# Utilidad centralizada para normalizar strings con acentos/caracteres especiales
# Reemplaza ~40 líneas de gsub repetidos en InitialContactForm
#
# Uso:
#   StringNormalizer.unaccent("José María")  => "Jose Maria"
#   StringNormalizer.to_code("Álvaro Obregón", max_length: 8)  => "ALVAROO"
#
class StringNormalizer
  ACCENT_MAP = {
    'á' => 'a', 'à' => 'a', 'ä' => 'a', 'â' => 'a',
    'Á' => 'A', 'À' => 'A', 'Ä' => 'A', 'Â' => 'A',
    'é' => 'e', 'è' => 'e', 'ë' => 'e', 'ê' => 'e',
    'É' => 'E', 'È' => 'E', 'Ë' => 'E', 'Ê' => 'E',
    'í' => 'i', 'ì' => 'i', 'ï' => 'i', 'î' => 'i',
    'Í' => 'I', 'Ì' => 'I', 'Ï' => 'I', 'Î' => 'I',
    'ó' => 'o', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o',
    'Ó' => 'O', 'Ò' => 'O', 'Ö' => 'O', 'Ô' => 'O',
    'ú' => 'u', 'ù' => 'u', 'ü' => 'u', 'û' => 'u',
    'Ú' => 'U', 'Ù' => 'U', 'Ü' => 'U', 'Û' => 'U',
    'ñ' => 'n', 'Ñ' => 'N'
  }.freeze

  # Remueve acentos, mantiene espacios y alfanuméricos
  def self.unaccent(text)
    return '' if text.blank?

    result = text.to_s.dup
    ACCENT_MAP.each { |accented, plain| result.gsub!(accented, plain) }
    result
  end

  # Código alfanumérico limpio (sin espacios ni caracteres especiales)
  def self.to_code(text, max_length: 10)
    unaccent(text)
      .upcase
      .gsub(/[^A-Z0-9]/, '')
      .slice(0, max_length)
      .presence || 'UNKNOWN'
  end

  # Código con padding (rellena con '0' hasta max_length)
  def self.to_padded_code(text, max_length: 8, pad_char: '0')
    to_code(text, max_length: max_length)
      .ljust(max_length, pad_char)
  end
end
