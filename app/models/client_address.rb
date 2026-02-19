# app/models/client_address.rb
class ClientAddress < ApplicationRecord
  belongs_to :client
  belongs_to :address

  accepts_nested_attributes_for :address

  ADDRESS_TYPES = %w[fiscal particular comercial legal].freeze

  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES }

  def display_label
    {
      "fiscal"     => "Fiscal",
      "particular" => "Particular",
      "comercial"  => "Comercial",
      "legal"      => "Legal"
    }[address_type] || address_type
  end
end

