class Role < ApplicationRecord
     include AutoSluggable
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

    def can_manage_role?(other_role)
      level < other_role.level
    end

    def superadmin?
      level == 0
    end

    def admin_or_above?
      level <= 10
    end

    def to_s
      display_name
    end
end
