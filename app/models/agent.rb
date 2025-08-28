class Agent < ApplicationRecord
  belongs_to :user
  has_many   :exclusivities, class_name: "PropertyExclusivity", dependent: :destroy
  has_many   :commissions, dependent: :nullify

  validates :license_number, :phone, :commission_rate, presence: true
  validates :commission_rate, numericality: { greater_than_or_equal_to: 0 }
end
