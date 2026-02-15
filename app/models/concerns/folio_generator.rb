# app/models/concerns/folio_generator.rb
# Concern compartido para generación de folios de contacto inicial.
# Usado por InitialContactForm y BusinessTransaction.
#
# Requisitos del modelo que incluye este concern:
#   - Debe existir la tabla initial_contact_forms con columna initial_contact_folio
#
# Uso:
#   include FolioGenerator
#   folio = generate_contact_folio("MNJ", Time.current)
#
module FolioGenerator
  extend ActiveSupport::Concern

  # Genera un folio único con formato: {initials}{ddmmyy}_{sequence}
  # Ejemplo: MNJ110226_01, MNJ110226_02
  def generate_contact_folio(initials, date)
    date_str = date.strftime('%d%m%y')
    base_folio = "#{initials}#{date_str}"

    last_folio = InitialContactForm
      .where("initial_contact_folio LIKE ?", "#{base_folio}%")
      .maximum('initial_contact_folio')

    sequence = if last_folio.present?
                 (last_folio.split('_').last.to_i + 1).to_s.rjust(2, '0')
               else
                 '01'
               end

    "#{base_folio}_#{sequence}"
  end

  # Extrae iniciales de un nombre o email
  def extract_initials_from_name(full_name)
    return full_name.split('@').first.upcase[0..2] if full_name.include?('@')

    parts = full_name.strip.split(/\s+/)

    case parts.length
    when 1 then parts[0].upcase[0..2]
    when 2 then "#{parts[0][0]}#{parts[1][0]}#{parts[0][1]}".upcase
    else "#{parts[0][0]}#{parts[1][0]}#{parts[2][0]}".upcase
    end
  end
end
