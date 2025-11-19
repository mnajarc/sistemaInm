# app/models/property_acquisition_method.rb
class PropertyAcquisitionMethod < ApplicationRecord
has_many :business_transactions
has_many :initial_contact_forms

validates :name, :code, presence: true, uniqueness: true

scope :active, -> { where(active: true) }
scope :ordered, -> { order(:sort_order, :name) }
scope :requires_succession, -> { where(requires_heirs: true) }
scope :requires_judicial, -> { where(requires_judicial_sentence: true) }
end
