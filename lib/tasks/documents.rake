# lib/tasks/documents.rake
namespace :documents do
  desc "Marcar documentos expirados automáticamente"
  task mark_expired: :environment do
    puts "🔍 Buscando documentos expirados..."
    
    count = DocumentSubmission
      .where(validation_status: 'approved')
      .where("expiry_date < ?", Date.current)
      .count
    
    if count.zero?
      puts "✅ No hay documentos expirados"
      return
    end
    
    puts "⏰ Marcando #{count} documento(s) como expirado(s)..."
    
    DocumentValidationService.check_and_mark_expired!
    
    puts "✅ Tarea completada: #{count} documento(s) marcado(s) como expirado(s)"
  end
end
