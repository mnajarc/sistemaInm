class Client < ApplicationRecord
    has_many :offered_transactions, 
             class_name: 'BusinessTransaction', 
             foreign_key: 'offering_client_id'
    has_many :acquired_transactions, 
             class_name: 'BusinessTransaction', 
             foreign_key: 'acquiring_client_id'
    has_many :offered_properties, through: :offered_transactions, source: :property
    has_many :acquired_properties, through: :acquired_transactions, source: :property
    
    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    
    def full_name_with_email
      "#{name} (#{email})"
    end
  end
  