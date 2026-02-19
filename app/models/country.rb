# app/models/country.rb
class Country < ApplicationRecord
  has_many :nationality_clients,
           class_name: "Client",
           foreign_key: :nationality_country_id

  has_many :birth_clients,
           class_name: "Client",
           foreign_key: :birth_country_id

  validates :name, presence: true
  validates :alpha2_code, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }

  def to_s
    name
  end
end

