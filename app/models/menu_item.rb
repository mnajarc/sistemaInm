class MenuItem < ApplicationRecord
  belongs_to :parent, class_name: 'MenuItem', optional: true
  has_many :children, class_name: 'MenuItem', foreign_key: 'parent_id', dependent: :destroy
  has_many :role_menu_permissions, dependent: :destroy
  has_many :roles, through: :role_menu_permissions
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :minimum_role_level, presence: true
  validates :sort_order, presence: true
  
  scope :active, -> { where(active: true) }
  scope :roots, -> { where(parent_id: nil) }
  scope :by_sort_order, -> { order(:sort_order, :display_name) }
  scope :visible_for_level, ->(level) { where('minimum_role_level >= ?', level) }
  
  before_validation :set_default_sort_order, on: :create
  
  def visible_for_role?(role_level)
    return false unless active?
    role_level <= minimum_role_level
  end
  
  def has_children?
    children.active.any?
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
