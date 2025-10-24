class DocumentChecklistService
  def initialize(transaction)
    @transaction = transaction
  end

  def checklist
    {
      summary: summary_stats,
      oferente: documents_for_party('oferente'),
      adquiriente: documents_for_party('adquiriente'),
      copropietarios: documents_by_co_owner
    }
  end

  private

  def summary_stats
    submissions = @transaction.document_submissions
    
    {
      total: submissions.count,
      uploaded: submissions.where.not(submitted_at: nil).count,
      pending: submissions.where(submitted_at: nil).count,
      validated: submissions.where.not(validated_at: nil).count,
      rejected: submissions.joins(:document_status).where(document_statuses: { name: 'rechazado' }).count,
      expired: submissions.expired.count,
      expiring_soon: submissions.expiring_soon.count,
      progress: calculate_progress(submissions)
    }
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
    co_owners = @transaction.business_transaction_co_owners
                            .where(active: true)
    
    return [] if co_owners.empty?
    
    co_owners.map do |co_owner|
      submissions = @transaction.document_submissions
                                .where(party_type: 'copropietario', 
                                       business_transaction_co_owner: co_owner)
                                .includes(:document_type, :document_status)
                                .order('document_types.category, document_types.name')
      
      {
        co_owner: {
          id: co_owner.id,
          name: co_owner.person_name.presence || co_owner.client&.name || "Copropietario ##{co_owner.id}",
          client_name: co_owner.client&.name,
          role: co_owner.role,
          percentage: co_owner.percentage,
          deceased: co_owner.deceased
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
              submission.business_transaction_co_owner.client&.name,
        role: submission.business_transaction_co_owner.role,
        percentage: submission.business_transaction_co_owner.percentage
      } : nil
    }

  end

  def calculate_progress(submissions)
    return 0 if submissions.count.zero?
    
    uploaded = submissions.uploaded.count
    ((uploaded.to_f / submissions.count) * 100).round(2)
  end
end