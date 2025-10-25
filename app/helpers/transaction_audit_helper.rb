module TransactionAuditHelper
  def event_icon(event_type)
    {
      'created' => 'plus-circle',
      'agent_changed' => 'exchange-alt',
      'document_uploaded' => 'file-upload',
      'document_validated' => 'check-circle',
      'completed' => 'flag-checkered'
    }[event_type] || 'info-circle'
  end
  
  def event_color(event_type)
    {
      'created' => 'primary',
      'agent_changed' => 'warning',
      'document_uploaded' => 'info',
      'document_validated' => 'success',
      'completed' => 'success'
    }[event_type] || 'secondary'
  end
  
  def format_audit_description(audit)
    if audit[:reason].present?
      "#{audit[:description]} - #{audit[:reason]}"
    else
      audit[:description]
    end
  end
end
