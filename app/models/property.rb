class Property < ApplicationRecord
  belongs_to :user        # Quien la crea
  has_many   :exclusivities, class_name: "PropertyExclusivity", dependent: :destroy
  has_many   :commissions, dependent: :nullify

  validates :price, :property_type,
            :status, :address, :city, :state, :postal_code,
            :built_area_m2, :lot_area_m2, presence: true
  validates :built_area_m2, :lot_area_m2, numericality: { greater_than: 0 }
  validates :price, numericality: { 
    greater_than: 0, 
    less_than: 1_000_000_000 
  }
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 10000 }
  validate :sanitize_input
  
  private
  
  def sanitize_input
    self.title = ActionController::Base.helpers.sanitize(title) if title.present?
    self.description = ActionController::Base.helpers.sanitize(description) if description.present?
  end
end