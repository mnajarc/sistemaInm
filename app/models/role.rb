class Role < ApplicationRecord
  include Configurable
  
  has_many :users, dependent: :restrict_with_error
  has_many :role_menu_permissions, dependent: :destroy
  has_many :menu_items, through: :role_menu_permissions
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :level, presence: true, uniqueness: true
  
  scope :active, -> { where(active: true) }
  scope :by_level, -> { order(:level) }
  scope :system_roles, -> { where(system_role: true) }
  scope :manageable_by, ->(user) { where("level > ?", user.role_level) }
  
  # ✅ MÉTODOS REFACTORIZADOS SIN HARDCODING
  def can_manage_role?(other_role)
    level < other_role.level
  end
  
  def superadmin?
    level <= get_config('roles.superadmin_max_level', 0)
  end
  
  def admin_or_above?
    level <= get_config('roles.admin_max_level', 10)
  end
  
  def agent_or_above?
    level <= get_config('roles.agent_max_level', 20)
  end
  
  def self.superadmin_role_names
    get_config('roles.superadmin_names', ['superadmin'])
  end
  
  def self.admin_role_names
    get_config('roles.admin_names', ['admin'])
  end
  
  def to_s
    display_name
  end
end