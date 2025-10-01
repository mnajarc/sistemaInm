# db/seeds/roles.rb
roles = [
  { name: "superadmin", display_name: I18n.t('roles.superadmin'), level: 0, system_role: true },
  { name: "admin",      display_name: I18n.t('roles.admin'),      level: 10, system_role: true },
  { name: "agent",      display_name: I18n.t('roles.agent'),      level: 20, system_role: false },
  { name: "client",     display_name: I18n.t('roles.client'),     level: 30, system_role: false }
]

roles.each do |attrs|
  Role.find_or_create_by!(name: attrs[:name]) do |r|
    r.display_name = attrs[:display_name]
    r.level        = attrs[:level]
    r.system_role  = attrs[:system_role]
    r.active       = true
  end
end
