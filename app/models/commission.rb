class Commission < ApplicationRecord
  belongs_to :property
  belongs_to :agent

  validates :amount, :commission_type, :status, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  scope :paid,   -> { where(status: "paid") }
  scope :pending,-> { where(status: "pending") }
end
