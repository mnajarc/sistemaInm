module Configurable
  extend ActiveSupport::Concern
  
  class_methods do
    def config_for(category)
      SystemConfiguration.category_hash(category)
    end
    
    def get_config(key, default = nil)
      SystemConfiguration.get(key, default)
    end
  end
  
  def config_for(category)
    self.class.config_for(category)
  end
  
  def get_config(key, default = nil)
    self.class.get_config(key, default)
  end
end