module BusinessTransactionsHelper
  def can_create_transactions?
    current_user&.agent_or_above?
  end
  
  def transaction_status_badge(transaction)
    status = transaction.business_status
    content_tag :span, status.display_name, 
                class: "badge bg-#{status.color}"
  end
  
  def operation_type_badge(operation_type)
    content_tag :span, operation_type.display_name,
                class: "badge bg-info"
  end
  
  def format_transaction_price(price)
    "$#{number_with_delimiter(price)}"
  end
end
