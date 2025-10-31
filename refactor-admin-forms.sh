#!/bin/bash
# Script para refactorizar formularios admin: display_name visible, name colapsado
# Sistema Inmobiliario v2 - Estandarización de catálogos

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Refactorización de Formularios${NC}"
echo -e "${GREEN}================================${NC}\n"

# PASO 1: Backup de vistas antes de modificar
BACKUP_DIR="backups_vistas_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}[BACKUP]${NC} Creando backup en $BACKUP_DIR..."
cp -r app/views/admin "$BACKUP_DIR/"
echo -e "${GREEN}✓${NC} Backup creado\n"

# PASO 2: Buscar todos los _form.html.erb en admin y subcarpetas
echo -e "${YELLOW}[BUSCAR]${NC} Encontrando formularios...\n"
FORM_FILES=$(find app/views/admin -name "_form.html.erb" -type f)

if [ -z "$FORM_FILES" ]; then
  echo -e "${RED}✗${NC} No se encontraron formularios _form.html.erb"
  exit 1
fi

echo "Formularios encontrados:"
echo "$FORM_FILES" | nl
echo ""

# PASO 3: Procesar cada formulario
PROCESSED=0
SKIPPED=0

for file in $FORM_FILES; do
  echo -e "${YELLOW}[PROCESANDO]${NC} $file"
  
  # Verificar si ya tiene el patrón nuevo (display_name)
  if grep -q "form.label :display_name" "$file"; then
    echo -e "${YELLOW}  ⊘ Ya tiene display_name, saltando...${NC}"
    ((SKIPPED++))
    continue
  fi
  
  # Verificar si tiene campo :name (si no, probablemente no es un catálogo)
  if ! grep -q "form.text_field :name" "$file" && ! grep -q "form.label :name" "$file"; then
    echo -e "${YELLOW}  ⊘ No parece ser un catálogo (no tiene campo :name), saltando...${NC}"
    ((SKIPPED++))
    continue
  fi
  
  # Crear archivo temporal
  TEMP_FILE="${file}.tmp"
  
  # TRANSFORMACIÓN:
  # 1. Buscar el campo :name y reemplazarlo con el nuevo patrón
  # 2. Si ya existe :display_name, solo colapsar :name
  
  # Estrategia: insertar el nuevo bloque ANTES del campo :name
  # y luego comentar/eliminar el :name viejo
  
  awk '
  BEGIN { 
    in_name_block = 0
    name_replaced = 0
  }
  
  # Detectar inicio del bloque del campo :name
  /<div.*mb-.*>/ && !name_replaced {
    line_buffer = $0
    getline
    if ($0 ~ /form\.label :name/) {
      # Encontramos el bloque :name, insertar nuevo código
      print "<!-- CAMPO DISPLAY_NAME (principal) -->"
      print "<div class=\"mb-3\">"
      print "  <%= form.label :display_name, \"Nombre visible\", class: \"form-label\" %>"
      print "  <%= form.text_field :display_name, class: \"form-control\", placeholder: \"Ej: Identificación oficial (INE/IFE)\" %>"
      print "  <small class=\"text-muted\">Nombre que verá el usuario final.</small>"
      print "</div>"
      print ""
      print "<!-- CAMPO NAME (colapsado, auto-generado) -->"
      print "<details class=\"mb-3\">"
      print "  <summary class=\"text-muted small\" style=\"cursor: pointer;\">"
      print "    ⚙️ Opciones avanzadas (ID técnico, auto-generado)"
      print "  </summary>"
      print "  <div class=\"mt-2 p-3 bg-light border rounded\">"
      print "    <%= form.label :name, \"Identificador técnico (auto-generado)\", class: \"form-label\" %>"
      print "    <%= form.text_field :name, class: \"form-control font-monospace\", readonly: true %>"
      print "    <small class=\"text-warning\">Solo edita esto si es estrictamente necesario.</small>"
      print "  </div>"
      print "</details>"
      print ""
      
      # Saltar el bloque viejo de :name (siguiente líneas hasta </div>)
      in_name_block = 1
      name_replaced = 1
      next
    } else {
      # No era el campo :name, imprimir normal
      print line_buffer
      print $0
      next
    }
  }
  
  # Si estamos dentro del bloque viejo de :name, saltarlo
  in_name_block && /<\/div>/ {
    in_name_block = 0
    next
  }
  
  in_name_block {
    next
  }
  
  # Líneas normales
  {
    print $0
  }
  ' "$file" > "$TEMP_FILE"
  
  # Reemplazar archivo original con el modificado
  mv "$TEMP_FILE" "$file"
  
  echo -e "${GREEN}  ✓ Procesado correctamente${NC}"
  ((PROCESSED++))
done

# PASO 4: Resumen
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}RESUMEN${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "Formularios procesados: ${GREEN}$PROCESSED${NC}"
echo -e "Formularios saltados:   ${YELLOW}$SKIPPED${NC}"
echo -e "Backup en:              ${YELLOW}$BACKUP_DIR${NC}"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "1. Verifica manualmente algunos formularios antes de commit"
echo "2. Ejecuta: git diff app/views/admin"
echo "3. Si algo salió mal, restaura desde: $BACKUP_DIR"
echo ""
echo -e "${GREEN}¡Listo!${NC} Ahora tus formularios usan display_name como campo principal."
