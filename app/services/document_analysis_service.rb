# app/services/document_analysis_service.rb
# Servicio de análisis automático de documentos con IA (gratuito)
# Optimizado para Rails 8 con Active Storage nativo

class DocumentAnalysisService
  attr_reader :submission

  def initialize(submission)
    @submission = submission
  end

  def analyze
    return unless @submission.document_file.attached?

    @submission.update!(analysis_status: 'processing')

    begin
      result = {
        file_info: extract_file_info,
        legibility: assess_legibility,
        ocr_text: extract_text,
        metadata: extract_metadata,
        validation: validate_against_type,
        analyzed_at: Time.current
      }

      @submission.update!(
        analysis_status: 'completed',
        analysis_result: result,
        ocr_text: result[:ocr_text],
        legibility_score: result[:legibility][:score],
        analyzed_at: Time.current,
        auto_validated: result[:validation][:auto_validate]
      )

      # Auto-validar si confianza es alta
      auto_validate_if_confident(result)

      result
    rescue StandardError => e
      @submission.update!(
        analysis_status: 'failed',
        analysis_result: { error: e.message }
      )
      Rails.logger.error "Document analysis failed for submission ##{@submission.id}: #{e.message}"
      raise
    end
  end

def extract_text_from_pdf(path)
  begin
    # 1. Intentar extraer texto nativo primero (más rápido y preciso)
    native_text = extract_native_pdf_text(path)
    
    # 2. Si el texto nativo es bueno, usarlo
    if native_text.present? && text_quality_good?(native_text)
      Rails.logger.info "Using native PDF text extraction"
      return native_text.force_encoding('UTF-8')
    end
    
    # 3. Si falla, hacer OCR en todas las páginas
    Rails.logger.info "Native text poor quality, using OCR"
    return extract_pdf_text_via_ocr(path)
    
  rescue StandardError => e
    Rails.logger.error "PDF text extraction failed: #{e.message}"
    ''
  end
end

private

def extract_native_pdf_text(path)
  # Usar pdftotext con mejor codificación
  text = `pdftotext -enc UTF-8 -layout "#{path}" - 2>/dev/null`.strip
  
  # Si está vacío, intentar sin layout
  if text.empty?
    text = `pdftotext -enc UTF-8 "#{path}" - 2>/dev/null`.strip
  end
  
  text
end

def text_quality_good?(text)
  return false if text.blank?
  return false if text.length < 20
  
  # Verificar que no tenga demasiados caracteres extraños
  strange_chars = text.count('ÃäÅÕãÁ@ÆÓÂÖÕÈÅØ')
  total_chars = text.length
  
  # Si más del 30% son caracteres extraños, considerarlo malo
  (strange_chars.to_f / total_chars) < 0.3
end

def extract_pdf_text_via_ocr(path)
  require 'rtesseract'
  
  all_text = []
  
  # OCR por página (hasta 5 páginas para evitar lentitud)
  max_pages = 5
  
  (0...max_pages).each do |page_num|
    temp_image = Tempfile.new(["pdf_ocr_page_#{page_num}", '.png'])
    
    # Convertir página a imagen con alta calidad para OCR
    conversion_result = system(
      "convert",
      "-density", "300",
      "-quality", "100",
      "#{path}[#{page_num}]",
      "-colorspace", "RGB",
      "-background", "white",
      "-flatten",
      temp_image.path
    )
    
    if conversion_result && File.size(temp_image.path) > 1000
      # OCR en español
      ocr = RTesseract.new(temp_image.path, lang: 'spa')
      page_text = ocr.to_s.strip
      
      all_text << page_text if page_text.length > 10
      
      Rails.logger.info "OCR página #{page_num + 1}: #{page_text.length} caracteres extraídos"
    end
    
    temp_image.close
    temp_image.unlink
  end
  
  all_text.join("\n\n")
end




  def extract_file_info
    file = @submission.document_file
    {
      filename: file.filename.to_s,
      content_type: file.content_type,
      size_bytes: file.byte_size,
      size_mb: (file.byte_size / 1.megabyte.to_f).round(2)
    }
  end

  def assess_legibility
    file_path = download_file
    
    legibility = if pdf_file?
      analyze_pdf_legibility(file_path)
    else
      analyze_image_legibility(file_path)
    end

    cleanup_temp_file(file_path)
    legibility
  end

  def analyze_image_legibility(path)
    require 'mini_magick'
    
    begin
      image = MiniMagick::Image.open(path)
      
      # Obtener dimensiones
      width = image.width
      height = image.height
      
      # Usar ImageMagick directamente para obtener estadísticas
      stats_output = `identify -verbose "#{path}" 2>&1`
      
      # Extraer standard deviation (indica sharpness y contraste)
      std_dev_match = stats_output.match(/standard deviation:\s*([\d.]+)/)
      std_dev = std_dev_match ? std_dev_match[1].to_f : 0
      
      # Extraer mean (indica brillo)
      mean_match = stats_output.match(/mean:\s*([\d.]+)/)
      mean = mean_match ? mean_match[1].to_f : 0
      
      # Determinar quantum range (normalización)
      quantum_match = stats_output.match(/Depth:\s*(\d+)-bit/)
      bit_depth = quantum_match ? quantum_match[1].to_i : 8
      quantum = (2 ** bit_depth) - 1
      
      # Calcular métricas normalizadas (0-100)
      sharpness = [(std_dev / quantum * 300).round(2), 100].min
      contrast = [(std_dev / quantum * 200).round(2), 100].min
      brightness = [(mean / quantum * 100).round(2), 100].min
      
      # Penalizar brillo extremo (muy oscuro o muy claro)
      brightness_penalty = 0
      if brightness < 30
        brightness_penalty = (30 - brightness) * 0.5
      elsif brightness > 70
        brightness_penalty = (brightness - 70) * 0.5
      end
      brightness = [brightness - brightness_penalty, 0].max
      
      # Score compuesto
      score = (sharpness * 0.5 + contrast * 0.3 + brightness * 0.2).round(2)
      
      {
        score: score,
        sharpness: sharpness,
        contrast: contrast,
        brightness: brightness,
        resolution: "#{width}x#{height}",
        warnings: generate_quality_warnings(score, sharpness, contrast)
      }
    rescue StandardError => e
      Rails.logger.error "Legibility analysis failed: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      { 
        score: 50, 
        sharpness: 50,
        contrast: 50,
        brightness: 50,
        resolution: 'unknown',
        warnings: ["No se pudo analizar calidad: #{e.message}"] 
      }
    end
  end

  def analyze_pdf_legibility(path, max_pages: 3)
    require 'mini_magick'
    
    begin
      # Detectar número de páginas
      pdf_info = `identify -format "%n\n" "#{path}" 2>&1`.lines.first&.to_i || 1
      pages_to_analyze = [pdf_info, max_pages].min
      
      Rails.logger.info "Analizando #{pages_to_analyze} página(s) del PDF"
      
      scores = []
      
      # Analizar cada página
      (0...pages_to_analyze).each do |page_num|
        temp_image = Tempfile.new(["pdf_page_#{page_num}", '.png'])
        
        # Convertir página a imagen
        conversion_result = system(
          "convert",
          "-density", "300",
          "-quality", "100",
          "#{path}[#{page_num}]",
          "-colorspace", "RGB",
          temp_image.path
        )
        
        next unless conversion_result
        
        # Analizar esta página
        page_result = analyze_image_legibility(temp_image.path)
        scores << {
          page: page_num + 1,
          score: page_result[:score],
          sharpness: page_result[:sharpness],
          contrast: page_result[:contrast],
          brightness: page_result[:brightness]
        }
        
        # Limpiar
        temp_image.close
        temp_image.unlink
      end
      
      if scores.empty?
        return {
          score: 50,
          sharpness: 50,
          contrast: 50,
          brightness: 50,
          resolution: 'unknown',
          warnings: ['No se pudo analizar ninguna página del PDF']
        }
      end
      
      # Calcular promedio
      avg_score = (scores.sum { |s| s[:score] } / scores.size.to_f).round(2)
      avg_sharpness = (scores.sum { |s| s[:sharpness] } / scores.size.to_f).round(2)
      avg_contrast = (scores.sum { |s| s[:contrast] } / scores.size.to_f).round(2)
      avg_brightness = (scores.sum { |s| s[:brightness] } / scores.size.to_f).round(2)
      
      # Detectar inconsistencias (puede indicar scan de mala calidad)
      variance = scores.map { |s| (s[:score] - avg_score) ** 2 }.sum / scores.size
      warnings = []
      
      if variance > 100
        warnings << 'Calidad inconsistente entre páginas'
      end
      
      if avg_score < 40
        warnings << 'Calidad general baja'
      end
      
      warnings << "Análisis basado en #{pages_to_analyze} página(s) del PDF"
      
      {
        score: avg_score,
        sharpness: avg_sharpness,
        contrast: avg_contrast,
        brightness: avg_brightness,
        resolution: "PDF #{pdf_info} página(s)",
        pages_analyzed: pages_to_analyze,
        page_scores: scores,
        warnings: warnings
      }
    rescue StandardError => e
      Rails.logger.error "PDF legibility analysis failed: #{e.message}"
      {
        score: 50,
        sharpness: 50,
        contrast: 50,
        brightness: 50,
        resolution: 'unknown',
        warnings: ["No se pudo analizar PDF: #{e.message}"]
      }
    end
  end




  def calculate_sharpness(image)
    # Método mejorado para detectar nitidez
    begin
      # Calcular varianza de Laplaciano (blur detection)
      temp_file = Tempfile.new(['blur_test', '.png'])
      
      # Aplicar filtro Laplaciano
      MiniMagick::Tool::Convert.new do |convert|
        convert << image.path
        convert.colorspace('Gray')
        convert.morphology('Convolve', 'Laplacian:0')
        convert << temp_file.path
      end
      
      # Calcular desviación estándar del resultado
      stats = MiniMagick::Image.open(temp_file.path)
      std_dev = stats["%[standard-deviation]"]&.to_f || 0
      
      temp_file.close
      temp_file.unlink
      
      # Normalizar a escala 0-100
      # Valores típicos: 0-0.3 (muy bajo = blur), 0.3-1.0 (bueno)
      score = [[(std_dev * 100).round(2), 100].min, 0].max
      
      score
    rescue => e
      Rails.logger.error "Error calculating sharpness: #{e.message}"
      50 # Fallback
    end
  end


  def calculate_contrast(image)
    # Calcular contraste usando desviación estándar
    stats = image.run_command('identify', '-format', '%[fx:standard_deviation]', image.path)
    std_dev = stats.to_f
    
    # Normalizar (0.0-1.0 típico, convertir a 0-100)
    (std_dev * 100).round(2)
  rescue StandardError
    50
  end

  def calculate_brightness(image)
    # Calcular brillo medio
    mean = image.run_command('identify', '-format', '%[fx:mean]', image.path).to_f
    
    # Óptimo es 0.4-0.6 (40-60%)
    brightness = (mean * 100).round(2)
    
    # Penalizar si está muy oscuro o muy claro
    if brightness < 30 || brightness > 70
      [brightness - 20, 0].max
    else
      brightness
    end
  rescue StandardError
    50
  end

  def generate_quality_warnings(score, sharpness, contrast)
    warnings = []
    warnings << 'Imagen borrosa o desenfocada' if sharpness < 30
    warnings << 'Bajo contraste, difícil de leer' if contrast < 20
    warnings << 'Documento de baja calidad' if score < 40
    warnings
  end

  def extract_text
    file_path = download_file
    
    text = if pdf_file?
      extract_text_from_pdf(file_path)
    else
      extract_text_from_image(file_path)
    end

    cleanup_temp_file(file_path)
    text&.strip || ''
  end

  def extract_text_from_image(path)
    require 'rtesseract'
    
    # OCR en español
    image = RTesseract.new(path, lang: 'spa')
    image.to_s.strip
  rescue StandardError => e
    Rails.logger.error "OCR failed: #{e.message}"
    ''
  end

  def extract_metadata
    text = @submission.ocr_text || extract_text
    
    metadata = {
      dates: extract_dates(text),
      names: extract_names(text),
      ids: extract_identifiers(text)
    }

    # Metadata específica por tipo
    case @submission.document_type.category
    when 'identidad'
      metadata.merge!(extract_id_metadata(text))
    when 'financieros'
      metadata.merge!(extract_financial_metadata(text))
    when 'propiedad'
      metadata.merge!(extract_property_metadata(text))
    end

    metadata
  end

  def extract_dates(text)
    dates = []
    
    # DD/MM/YYYY
    dates += text.scan(/\b(\d{1,2}\/\d{1,2}\/\d{4})\b/)
    
    # DD-MM-YYYY
    dates += text.scan(/\b(\d{1,2}-\d{1,2}-\d{4})\b/)
    
    # Texto: "01 de Enero de 2024"
    dates += text.scan(/\b(\d{1,2}\s+de\s+\w+\s+de\s+\d{4})\b/i)
    
    dates.flatten.uniq
  end

  def extract_names(text)
    # Extraer nombres propios (simplificado)
    # Palabras capitalizadas de 2+ caracteres
    text.scan(/\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\b/)
  end

  def extract_identifiers(text)
    ids = {}
    
    # CURP: 18 caracteres alfanuméricos
    curp = text.scan(/\b[A-Z]{4}\d{6}[HM][A-Z]{5}\d{2}\b/)
    ids[:curp] = curp.first if curp.any?
    
    # RFC: 12-13 caracteres
    rfc = text.scan(/\b[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}\b/)
    ids[:rfc] = rfc.first if rfc.any?
    
    ids
  end

  def extract_id_metadata(text)
    {
      curp: extract_identifiers(text)[:curp],
      rfc: extract_identifiers(text)[:rfc],
      ine_number: text.scan(/\b\d{13}\b/).first
    }
  end

  def extract_financial_metadata(text)
    {
      amounts: text.scan(/\$\s*[\d,]+\.\d{2}/).map { |a| a.gsub(/[$,\s]/, '').to_f },
      account_numbers: text.scan(/\b\d{10,18}\b/)
    }
  end

  def extract_property_metadata(text)
    {
      folio_real: text.scan(/folio\s*real[:\s]*(\d+)/i).flatten.first,
      escritura: text.scan(/escritura[:\s]*(\d+)/i).flatten.first
    }
  end

  def validate_against_type
    confidence_score = 0
    issues = []
    
    expected_keywords = document_type_keywords
    ocr_text = @submission.ocr_text || ''
    found_keywords = expected_keywords.select { |kw| ocr_text_contains?(kw, ocr_text) }
    
    if found_keywords.any?
      confidence_score = (found_keywords.size.to_f / expected_keywords.size * 100).round(2)
    end
    
    issues << 'Documento no coincide con tipo esperado' if confidence_score < 30
    issues << 'Faltan datos clave del documento' if @submission.analysis_result.blank? || 
                                                     @submission.analysis_result.dig('metadata', 'dates').blank?
    
    {
      confidence_score: confidence_score,
      found_keywords: found_keywords,
      issues: issues,
      auto_validate: confidence_score > 70 && issues.empty? && (@submission.legibility_score || 0) > 60
    }
  end

  def document_type_keywords
    case @submission.document_type.name
    when /INE|IFE/i
      %w[INE credencial votar electoral]
    when /CURP/i
      %w[CURP población registro]
    when /RFC/i
      %w[RFC contribuyentes hacienda SAT]
    when /domicilio/i
      %w[luz agua CFE telmex servicio]
    when /cuenta/i
      %w[banco cuenta saldo movimientos]
    else
      []
    end
  end

  def ocr_text_contains?(keyword, text)
    text.downcase.include?(keyword.downcase)
  end

  def auto_validate_if_confident(result)
    return unless result[:validation][:auto_validate]
    
    validated_status = DocumentStatus.find_by(name: 'validado')
    @submission.update!(
      document_status: validated_status,
      validated_at: Time.current,
      validation_notes: 'Auto-validado por IA'
    ) if validated_status
  end

  def download_file
    # Rails 8: usar download directamente
    tempfile = Tempfile.new(['document', File.extname(@submission.document_file.filename.to_s)])
    tempfile.binmode
    tempfile.write(@submission.document_file.download)
    tempfile.close
    tempfile.path
  end

  def cleanup_temp_file(path)
    File.delete(path) if File.exist?(path)
  rescue StandardError
    # Ignorar errores de limpieza
  end

  def pdf_file?
    @submission.document_file.content_type == 'application/pdf'
  end
end
