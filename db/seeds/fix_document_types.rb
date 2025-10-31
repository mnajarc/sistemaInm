# db/seeds/fix_document_types.rb
# Script para corregir DocumentTypes: convierte display_name a name (snake_case)

def slugify(text)
  text.unicode_normalize(:nfd)
      .gsub(/[\u0300-\u036f]/, '')    # Quitar acentos
      .downcase
      .strip
      .gsub(/[^a-z0-9\s-]/, '')        # Solo alfanuméricos y -
      .gsub(/\s+/, '_')                # Espacios → _
      .gsub(/_+/, '_')                 # Múltiples _ → uno
end

puts "\n" + "=" * 80
puts "CORRIGIENDO DOCUMENT TYPES"
puts "=" * 80

total = DocumentType.count
puts "\n📊 Total a procesar: #{total}"

correcciones = 0
conflictos = 0
sin_cambios = 0

DocumentType.find_each do |dt|
  # Si el name tiene mayúsculas, espacios o caracteres especiales, necesita corrección
  if dt.name != dt.name.downcase || dt.name.include?(' ') || dt.name.include?('(') || dt.name.include?(')')
    nuevo_name = slugify(dt.name)
    
    # Verificar que sea diferente
    if dt.name == nuevo_name
      sin_cambios += 1
      next
    end
    
    # Verificar unicidad
    if DocumentType.where(name: nuevo_name).where.not(id: dt.id).exists?
      puts "  ⚠️  #{dt.id}: Conflicto '#{dt.name}' → '#{nuevo_name}' (YA EXISTE)"
      conflictos += 1
      next
    end
    
    puts "  ✓ #{dt.id}: '#{dt.name}' → '#{nuevo_name}'"
    dt.update_column(:name, nuevo_name)
    correcciones += 1
  else
    sin_cambios += 1
  end
end

puts "\n" + "=" * 80
puts "RESULTADO:"
puts "  ✅ Corregidos: #{correcciones}"
puts "  ⚠️  Conflictos: #{conflictos}"
puts "  ⊘  Sin cambios: #{sin_cambios}"
puts "  📊 Total procesado: #{total}"
puts "=" * 80 + "\n"
