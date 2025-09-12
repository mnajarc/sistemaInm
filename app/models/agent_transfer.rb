class AgentTransfer < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :from_agent
  belongs_to :to_agent
  belongs_to :transferred_by
end
