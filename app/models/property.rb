class Property < ApplicationRecord
  belongs_to :user        # Quien la crea
  has_many   :exclusivities, class_name: "PropertyExclusivity", dependent: :destroy
  has_many   :commissions, dependent: :nullify

  validates :title, :description, :price, :property_type,
            :status, :address, :city, :state, :postal_code,
            :built_area_m2, :lot_area_m2, presence: true
  validates :price, :built_area_m2, :lot_area_m2, numericality: { greater_than: 0 }
end
