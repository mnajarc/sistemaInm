# app/models/address.rb
class Address < ApplicationRecord
  has_many :client_addresses, dependent: :destroy
  has_many :clients, through: :client_addresses

  def full_address
    parts = []
    parts << "#{street} #{exterior_number}" if street.present?
    parts << "Int. #{interior_number}" if interior_number.present?
    parts << neighborhood if neighborhood.present?
    parts << municipality if municipality.present?
    parts << state if state.present?
    parts << "CP #{postal_code}" if postal_code.present?
    parts << country if country.present?
    parts.join(", ")
  end

  def short_address
    [street, exterior_number, neighborhood].compact.join(" ")
  end
end

