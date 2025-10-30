# app/models/instance_config.rb
class InstanceConfig < ApplicationRecord
  self.table_name = 'instance_config'
  
  validates :app_name, presence: true
  
  # Singleton pattern
  def self.current
    find_or_create_by(id: 1) do |config|
      config.app_name = "inmobInteligeria"
      config.instance_name = ENV['INSTANCE_NAME'] || 'default'
      config.organization_name = ENV['ORGANIZATION_NAME'] || 'Unknown'
    end
  end
  
  def self.update_setting(key, value)
    current.update(key => value)
  end
end
