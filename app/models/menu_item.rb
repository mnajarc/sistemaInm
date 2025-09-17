class MenuItem < ApplicationRecord
  belongs_to :parent, class_name: 'MenuItem', optional: true
  has_many :children, class_name: 'MenuItem', foreign_key: 'parent_id', dependent: :destroy
  has_many :role_menu_permissions, dependent: :destroy
  has_many :roles, through: :role_menu_permissions
  
  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :display_name, presence: true
  validates :minimum_role_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # ✅ SCOPES BÁSICOS
  scope :active, -> { where(active: true) }
  scope :roots, -> { where(parent_id: nil) }
  scope :root_menus, -> { where(parent_id: nil) }
  scope :by_order, -> { order(:sort_order) }
  scope :by_sort_order, -> { order(:sort_order) }
  scope :system_menus, -> { where(system_menu: true) }
  scope :custom_menus, -> { where(system_menu: false) }
  
  # ✅ SCOPE PARA ACCESIBILIDAD
  scope :accessible_to, ->(user) {
    return none unless user
    
    joins(:role_menu_permissions)
      .joins('JOIN roles ON roles.id = role_menu_permissions.role_id')
      .where('roles.level <= ? AND role_menu_permissions.can_view = ?', 
             user.role&.level || 999, true)
      .where(active: true)
      .distinct
  }
  
  # ✅ MÉTODOS DE INSTANCIA
  def accessible_to?(user)
    return false unless user&.role
    return false unless active?
    
    # Verificar nivel mínimo de rol
    return false if user.role.level > minimum_role_level
    
    # Verificar permisos específicos
    permission = role_menu_permissions.joins(:role)
                                    .where('roles.level <= ?', user.role.level)
                                    .where(can_view: true)
                                    .first
    
    permission.present?
  end
  
  def has_children?
    children.any?
  end
  
  def root?
    parent_id.nil?
  end
  
  def leaf?
    children.empty?
  end
  
  def full_path
    return name unless parent
    "#{parent.full_path} > #{name}"
  end
  
  def icon_html
    return '' unless icon.present?
    "<i class='#{icon}'></i>".html_safe
  end
  
  def depth
    return 0 unless parent
    parent.depth + 1
  end
  
  def siblings
    return MenuItem.none unless parent
    parent.children.where.not(id: id)
  end
  
  def ancestors
    return [] unless parent
    parent.ancestors + [parent]
  end
  
  def descendants
    result = children.to_a
    children.each { |child| result += child.descendants }
    result
  end
  
  # ✅ MÉTODOS DE CLASE PARA NAVEGACIÓN
  def self.main_navigation(user)
    accessible_to(user)
      .roots
      .by_order
      .includes(:children)
  end
  
  def self.admin_sidebar(user)
    admin_parent = find_by(name: 'administration')
    return none unless admin_parent
    
    accessible_to(user)
      .where(parent: admin_parent)
      .by_order
  end
  
  def self.superadmin_sidebar(user)
    superadmin_parent = find_by(name: 'superadmin')
    return none unless superadmin_parent
    
    accessible_to(user)
      .where(parent: superadmin_parent)
      .by_order
  end
  
  # ✅ MÉTODOS PARA GESTIÓN JERÁRQUICA
  def self.build_tree(items = nil)
    items ||= includes(:children).order(:sort_order)
    grouped = items.group_by(&:parent_id)
    
    build_tree_recursive(grouped, nil)
  end
  
  def self.build_tree_recursive(grouped, parent_id)
    (grouped[parent_id] || []).map do |item|
      {
        item: item,
        children: build_tree_recursive(grouped, item.id)
      }
    end
  end
  
  # ✅ MÉTODOS PARA FORMULARIOS SELECT
  def self.for_select(exclude_id = nil)
    items = roots.by_order.includes(:children)
    items = items.where.not(id: exclude_id) if exclude_id
    
    options = []
    items.each do |item|
      options << ["#{item.display_name}", item.id]
      build_select_options_recursive(item.children.by_order, options, 1, exclude_id)
    end
    options
  end
  
  def self.build_select_options_recursive(children, options, depth, exclude_id)
    prefix = "—" * depth + " "
    children.each do |child|
      next if exclude_id && child.id == exclude_id
      options << ["#{prefix}#{child.display_name}", child.id]
      build_select_options_recursive(child.children.by_order, options, depth + 1, exclude_id)
    end
  end
  
  # ✅ VALIDACIONES ADICIONALES
  def validate_no_circular_reference
    return unless parent_id
    
    if parent_id == id
      errors.add(:parent_id, "no puede ser el mismo elemento")
      return
    end
    
    if ancestors.include?(self)
      errors.add(:parent_id, "crearía una referencia circular")
    end
  end
  
  validate :validate_no_circular_reference, if: :parent_id_changed?
  
  # ✅ CALLBACKS
  before_save :set_sort_order, if: :new_record?
  after_update :update_children_paths, if: :saved_change_to_display_name?
  
  private
  
  def set_sort_order
    return if sort_order.present?
    
    if parent
      last_sibling = parent.children.order(:sort_order).last
      self.sort_order = last_sibling ? last_sibling.sort_order + 10 : 10
    else
      last_root = MenuItem.roots.order(:sort_order).last
      self.sort_order = last_root ? last_root.sort_order + 10 : 10
    end
  end
  
  def update_children_paths
    # Actualizar rutas de hijos si es necesario
    # Implementar si tienes campos calculados que dependan de nombres padre
  end
end
