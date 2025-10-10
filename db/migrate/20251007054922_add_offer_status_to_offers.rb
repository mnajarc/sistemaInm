class AddOfferStatusToOffers < ActiveRecord::Migration[8.0]
  def change
    add_reference :offers, :offer_status, null: false, foreign_key: true
  end
end
