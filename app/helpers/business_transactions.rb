module BusinessTransactionsHelper
  def can_create_transactions?
    current_user&.agent_or_above?
  end
end
