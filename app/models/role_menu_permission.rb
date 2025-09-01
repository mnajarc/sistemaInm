class RoleMenuPermission < ApplicationRecord
    belongs_to :role
    belongs_to :menu_item
    
    validates :role_id, uniqueness: { scope: :menu_item_id }
    
    scope :viewable, -> { where(can_view: true) }
    scope :editable, -> { where(can_edit: true) }
  end
  