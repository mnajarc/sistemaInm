# db/seeds/operation_types.rb
ops = [
  { name: "sale", display_name: I18n.t('operation_types.sale'), description: "Venta de propiedad", active: true, sort_order: 1 },
  { name: "rent", display_name: I18n.t('operation_types.rent'), description: "Alquiler de propiedad", active: true, sort_order: 2 }
]

ops.each do |attrs|
  OperationType.find_or_create_by!(name: attrs[:name]) do |o|
    o.display_name = attrs[:display_name]
    o.description  = attrs[:description]
    o.active       = attrs[:active]
    o.sort_order   = attrs[:sort_order]
  end
end
