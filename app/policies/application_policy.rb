class ApplicationPolicy
  include Configurable
  
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  def update?
    user.present?
  end

  def edit?
    update?
  end

  def destroy?
    user.present?
  end

  class Scope
    include Configurable
    
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end
    
    private
    
    def get_config(key, default = nil)
      if defined?(SystemConfiguration)
        SystemConfiguration.get(key, default)
      else
        default
      end
    rescue => e
      Rails.logger.error "Error getting config in #{self.class}: #{e.message}"
      default
    end
  end
  
  private
  
  def get_config(key, default = nil)
    if defined?(SystemConfiguration)
      SystemConfiguration.get(key, default)
    else
      default
    end
  rescue => e
    Rails.logger.error "Error getting config in #{self.class}: #{e.message}"
    default
  end
end