class OfferStatus < ApplicationRecord
     include AutoSluggable
  has_many :offers

  validates :name, :status_code, :display_name, presence: true
  validates :status_code, uniqueness: true
end
