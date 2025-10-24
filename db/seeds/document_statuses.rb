# db/seeds/document_statuses.rb (crear archivo)
puts "🔄 Creando estados de documentos..."

statuses = [
  { 
    name: 'pendiente_solicitud', 
    description: 'Documento aún no solicitado al cliente', 
    color: 'secondary', 
    icon: 'clock', 
    position: 1 
  },
  { 
    name: 'solicitado_cliente', 
    description: 'Solicitado al cliente, esperando entrega', 
    color: 'info', 
    icon: 'envelope', 
    position: 2 
  },
  { 
    name: 'recibido_revision', 
    description: 'Recibido, pendiente de validación técnica', 
    color: 'warning', 
    icon: 'eye', 
    position: 3 
  },
  { 
    name: 'observaciones', 
    description: 'Con observaciones, requiere corrección', 
    color: 'danger', 
    icon: 'exclamation-circle', 
    position: 4 
  },
  { 
    name: 'validado_vigente', 
    description: 'Validado correctamente y vigente', 
    color: 'success', 
    icon: 'check-circle', 
    position: 5 
  },
  { 
    name: 'vencido', 
    description: 'Documento vencido, requiere renovación', 
    color: 'danger', 
    icon: 'calendar-x', 
    position: 6 
  },
  { 
    name: 'rechazado', 
    description: 'Rechazado por ser deforme o ilegible', 
    color: 'dark', 
    icon: 'x-circle', 
    position: 7 
  },
  { 
    name: 'no_aplica', 
    description: 'No aplica para este tipo de transacción', 
    color: 'muted', 
    icon: 'dash-circle', 
    position: 8 
  }
]

statuses.each do |attrs|
  status = DocumentStatus.find_or_create_by!(name: attrs[:name]) do |s|
    s.attributes = attrs
  end
  puts "  ✅ #{status.name}"
end

puts "📄 #{DocumentStatus.count} estados de documentos creados"
