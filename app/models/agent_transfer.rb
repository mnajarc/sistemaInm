# app/models/agent_transfer.rb
class AgentTransfer < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :from_agent, class_name: 'User'
  belongs_to :to_agent, class_name: 'User'
  belongs_to :transferred_by, class_name: 'User'
  
  validates :reason, presence: true
  validates :transferred_at, presence: true
  
  scope :recent, -> { order(transferred_at: :desc) }
  scope :by_transaction, ->(transaction) { where(business_transaction: transaction) }
  
  def from_agent_name
    from_agent&.email || "Usuario ##{from_agent_id}"
  end
  
  def to_agent_name
    to_agent&.email || "Usuario ##{to_agent_id}"
  end
  
  def transferred_by_name
    transferred_by&.email || "Usuario ##{transferred_by_id}"
  end
  
  def transfer_summary
    "#{from_agent_name} → #{to_agent_name}"
  end
end