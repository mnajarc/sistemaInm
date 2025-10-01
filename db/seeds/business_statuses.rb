# db/seeds/business_statuses.rb
statuses = [
  { name: "available", display_name: I18n.t('business_statuses.available'), description: "Listo para oferta", color: "success", active: true, sort_order: 1 },
  { name: "reserved",  display_name: I18n.t('business_statuses.reserved'),  description: "Oferta en proceso", color: "warning", active: true, sort_order: 2 },
  { name: "sold",      display_name: I18n.t('business_statuses.sold'),      description: "Propiedad vendida", color: "primary", active: true, sort_order: 3 },
  { name: "rented",    display_name: I18n.t('business_statuses.rented'),    description: "Propiedad rentada", color: "info",    active: true, sort_order: 4 }
]

statuses.each do |attrs|
  BusinessStatus.find_or_create_by!(name: attrs[:name]) do |s|
    s.display_name = attrs[:display_name]
    s.description  = attrs[:description]
    s.color        = attrs[:color]
    s.active       = attrs[:active]
    s.sort_order   = attrs[:sort_order]
  end
end
