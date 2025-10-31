class MenuItem < ApplicationRecord
     include AutoSluggable
  belongs_to :parent, class_name: "MenuItem", optional: true
  has_many :children, class_name: "MenuItem", foreign_key: "parent_id", dependent: :destroy
  has_many :role_menu_permissions, dependent: :destroy
  has_many :roles, through: :role_menu_permissions

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :minimum_role_level, presence: true
  validates :sort_order, presence: true

  scope :active, -> { where(active: true) }
  scope :roots, -> { where(parent_id: nil) }
  scope :by_sort_order, -> { order(:sort_order, :display_name) }
  scope :visible_for_level, ->(level) { where("minimum_role_level >= ?", level) }
  scope :parent_items, -> { where(parent_id: nil) }
  # MÉTODO CRÍTICO para menús dinámicos
  scope :accessible_for_user, ->(user) {
    return none unless user&.role
    
    where(active: true)
      .where('minimum_role_level >= ?', user.role.level)
      .joins(:role_menu_permissions)
      .where(role_menu_permissions: { role: user.role, can_view: true })
      .distinct
      .order(:sort_order)
  }

  before_validation :set_default_sort_order, on: :create
  
  def visible_for_role?(role_level)
    return false unless active?
    return false if role_level > minimum_role_level
    
    # Verificar permisos específicos
    permission = role_menu_permissions.joins(:role)
                                    .where('roles.level = ?', role_level)
                                    .where(can_view: true)
                                    .first
    
    permission.present?
  end

  def has_children?
    children.where(active: true).any?
  end

  def accessible_children_for_user(user)
    children.accessible_for_user(user).order(:sort_order)
  end
  def breadcrumb
    items = []
    current = self
    while current
      items.unshift(current)
      current = current.parent
    end
    items
  end

  def depth
    breadcrumb.length - 1
  end

  def to_s
    display_name
  end

  def self.main_navigation(user)
    accessible_for_user(user).parent_items.includes(:children)
  end

  private

  def set_default_sort_order
    return if sort_order.present?

    if parent_id
      max_order = MenuItem.where(parent_id: parent_id).maximum(:sort_order) || 0
    else
      max_order = MenuItem.roots.maximum(:sort_order) || 0
    end

    self.sort_order = max_order + 10
  end
end
