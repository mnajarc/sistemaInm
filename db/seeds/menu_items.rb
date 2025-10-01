# db/seeds/menu_items.rb
MenuItem.transaction do
  # Panel principal
  dashboard = MenuItem.find_or_create_by!(name: "dashboard") do |m|
    m.display_name      = I18n.t('menu.dashboard')
    m.path              = "/dashboard"
    m.icon              = "dashboard"
    m.sort_order        = 1
    m.minimum_role_level = 30
  end

  # Propiedades (hijo de dashboard)
  MenuItem.find_or_create_by!(name: "properties") do |m|
    m.display_name      = I18n.t('menu.properties')
    m.path              = "/properties"
    m.icon              = "home"
    m.parent            = dashboard
    m.sort_order        = 2
    m.minimum_role_level = 20
  end

  # Transacciones (hijo de dashboard)
  MenuItem.find_or_create_by!(name: "transactions") do |m|
    m.display_name      = I18n.t('menu.transactions')
    m.path              = "/business_transactions"
    m.icon              = "swap_horiz"
    m.parent            = dashboard
    m.sort_order        = 3
    m.minimum_role_level = 20
  end

  # Administración (solo admin y superadmin)
  MenuItem.find_or_create_by!(name: "admin_panel") do |m|
    m.display_name      = I18n.t('menu.admin_panel')
    m.path              = "/admin"
    m.icon              = "admin_panel_settings"
    m.sort_order        = 99
    m.minimum_role_level = 10
  end
end
