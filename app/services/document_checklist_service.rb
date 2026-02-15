class DocumentChecklistService
  def initialize(transaction)
    @transaction = transaction
  end

  def checklist
    {
      summary: summary_stats,
      # oferente: documents_for_party('oferente'),
      copropietarios: documents_by_co_owner,
      adquiriente: documents_for_party('adquiriente')
    }
  end

  private


  def summary_stats
    submissions = @transaction.document_submissions
    
    # ✅ Agrupar por estado (ahora todos tienen estado)
    by_status = submissions.joins(:document_status)
                          .group('document_statuses.name')
                          .count
    
    # ✅ Estados específicos
    validated = by_status['validado_vigente'] || 0
    rejected = by_status['rechazado'] || 0
    expired = by_status['vencido'] || 0
    expiring_soon = by_status['por_vencer'] || 0
    
    # ✅ FÓRMULA CORRECTA: Pendientes = Total - Validados
    # Lo que falta por validar (cualquier estado excepto validado)
    pending = submissions.count - validated
    
    # ✅ Solo documentos ACTIVOS (no vencidos) para progreso
    active_submissions = submissions.where.not(
      id: submissions.joins(:document_status)
                    .where(document_statuses: { name: 'vencido' })
                    .select(:id)
    )
    
    {
      total: submissions.count,
      uploaded: submissions.where.not(submitted_at: nil).count,
      
      # ✅ Lógica clara y simple
      pending: pending,           # P = T - V (lo que falta)
      validated: validated,       # Aprobados
      rejected: rejected,         # Rechazados
      
      # ☠️ MUERTOS (fuera del flujo activo)
      expired: expired,
      
      # ⏰ TIME-DEPENDENT (cercanos a vencer, aún vivos)
      expiring_soon: expiring_soon,
      
      # Métricas adicionales
      active_count: active_submissions.count,
      progress: calculate_progress(active_submissions)
    }
  end


  def calculate_progress(submissions)
    return 0 if submissions.empty?
    
    # Solo documentos ACTIVOS (no vencidos)
    active = submissions.reject { |s| s.document_status&.name == 'vencido' }
    return 0 if active.empty?
    
    # Contar validados dentro de activos
    validated = active.count { |s| s.document_status&.name == 'validado_vigente' }
    ((validated.to_f / active.count) * 100).round(2)
  end







  def documents_for_party(party_type)
    submissions = @transaction.document_submissions
                              .where(party_type: party_type)
                              .includes(:document_type, :document_status, :uploaded_by, :validated_by)
                              .order('document_types.category, document_types.name')

    {
      total: submissions.count,
      uploaded: submissions.select(&:uploaded?).count,
      validated: submissions.select { |s| s.validated_at.present? }.count,
      documents: group_by_category(submissions)
    }
  end


def documents_by_co_owner
  co_owners = @transaction.business_transaction_co_owners.all
  
  return [] if co_owners.empty?
  
  co_owners.map.with_index do |co_owner, index|
    # ✅ FIJO: El principal recibe AMBOS tipos de documentos
    if index.zero?  # Es el principal
      submissions = @transaction.document_submissions
                                .where(business_transaction_co_owner: co_owner)
                                .where(party_type: ['copropietario_principal', 'copropietario'])
    else  # Son los herederos
      submissions = @transaction.document_submissions
                                .where(party_type: 'copropietario', 
                                      business_transaction_co_owner: co_owner)
    end
    
    submissions = submissions
                  .includes(:document_type, :document_status)
                  .order('document_types.category, document_types.name')
    
    {
      co_owner: {
        id: co_owner.id,
        name: co_owner.person_name.presence || co_owner.client&.full_name || "Copropietario ##{co_owner.id}",
        client_name: co_owner.client&.full_name,
        role: co_owner.role,
        percentage: co_owner.percentage,
        deceased: co_owner.deceased,
        active: co_owner.active,
        is_primary: index.zero?
      },
      documents: {
        total: submissions.count,
        uploaded: submissions.select(&:uploaded?).count,
        validated: submissions.select { |s| s.validated_at.present? }.count,
        list: group_by_category(submissions)
      }
    }
  end
end






  def group_by_category(submissions)
    submissions.group_by { |s| s.document_type.category }.map do |category, docs|
      {
        category: category,
        category_display: category.titleize,
        documents: docs.map { |doc| format_single_document(doc) }
      }
    end
  end

  def format_single_document(submission)
    {
      id: submission.id,
      submission: submission,
      document_type: {
        id: submission.document_type.id,
        name: submission.document_type.name,
        display_name: submission.document_type.name,  # Ya no usamos display_name
        category: submission.document_type.category
      },
      status: {
        name: submission.document_status&.name || 'sin_estado',
        display_name: (submission.document_status&.name || 'sin_estado').titleize,
        badge_class: submission.status_badge_class
      },
      uploaded: submission.uploaded?,
      uploaded_at: submission.submitted_at,
      uploaded_by: submission.uploaded_by&.email,
      validated: submission.validated_at.present?,
      validated_by: submission.validated_by&.email,
      validated_at: submission.validated_at,
      expiry_date: submission.expiry_date,
      expired: submission.expired?,
      expiring_soon: submission.expiring_soon?,
      analysis: {
        status: submission.analysis_status,
        legibility_score: submission.legibility_score,
        legibility_status: submission.legibility_status,
        auto_validated: submission.auto_validated
      },
      co_owner: submission.business_transaction_co_owner ? {
        id: submission.business_transaction_co_owner.id,
        name: submission.business_transaction_co_owner.person_name.presence || 
              submission.business_transaction_co_owner.client&.full_name,
        role: submission.business_transaction_co_owner.role,
        percentage: submission.business_transaction_co_owner.percentage
      } : nil
    }

  end

end
