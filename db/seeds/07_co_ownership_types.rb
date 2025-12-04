puts "🌱 Creando tipos de copropiedad (respaldo + nuevos legales)..."

co_ownership_types = [
  # ═══════════════════════════════════════════════════════════════
  # DATOS ORIGINALES DE TU RESPALDO
  # ═══════════════════════════════════════════════════════════════
  {
    name: 'individual',
    display_name: 'Propietario Único',
    description: 'Una sola persona es propietaria',
    ownership_mode: 'único',
    sort_order: 1
  },
  {
    name: 'joint_married',
    display_name: 'Bienes Mancomunados',
    description: 'Matrimonio con bienes en común',
    ownership_mode: 'dividido',
    sort_order: 2
  },
  {
    name: 'inheritance',
    display_name: 'Herencia',
    description: 'Múltiples herederos',
    ownership_mode: 'dividido',
    sort_order: 3
  },
  {
    name: 'joint_ownership',
    display_name: 'Copropiedad',
    description: 'Múltiples propietarios por acuerdo',
    ownership_mode: 'dividido',
    sort_order: 4
  },
  {
    name: 'corporation',
    display_name: 'Corporativo',
    description: 'Propiedad de persona moral',
    ownership_mode: 'dividido',
    sort_order: 5
  },
  {
    name: 'trust',
    display_name: 'Fideicomiso',
    description: 'Propiedad en fideicomiso',
    ownership_mode: 'dividido',
    sort_order: 6
  },
  {
    name: 'casado_bienes_separado',
    display_name: 'Régimen separación de bienes',
    description: 'Casado bajo régimen de separación de bienes',
    ownership_mode: 'único',
    sort_order: 7
  },

  # ═══════════════════════════════════════════════════════════════
  # TIPOS LEGALES ADICIONALES (NUEVOS)
  # ═══════════════════════════════════════════════════════════════
  
  # Regímenes Matrimoniales Adicionales
  {
    name: 'sociedad_conyugal',
    display_name: 'Sociedad Conyugal',
    description: 'Régimen matrimonial donde los bienes se comparten entre cónyuges',
    ownership_mode: 'dividido',
    sort_order: 10
  },
  {
    name: 'concubinato',
    display_name: 'Concubinato (Unión Libre)',
    description: 'Situación de dos personas que viven maritalmente sin estar casadas',
    ownership_mode: 'dividido',
    sort_order: 11
  },

  # Sucesiones Adicionales
  {
    name: 'herencia_abierta',
    display_name: 'Herencia Abierta',
    description: 'Propiedad en proceso de sucesión, con herederos definidos pero no certificados',
    ownership_mode: 'dividido',
    sort_order: 20
  },
  {
    name: 'herencia_testamentaria',
    display_name: 'Herencia Cerrada (Testamentaria)',
    description: 'Sucesión ya declarada por vía testamentaria',
    ownership_mode: 'dividido',
    sort_order: 21
  },
  {
    name: 'herencia_intestada',
    display_name: 'Herencia Cerrada (Intestada)',
    description: 'Sucesión declarada por vía intestada (sin testamento)',
    ownership_mode: 'dividido',
    sort_order: 22
  },
  {
    name: 'adjudicacion_notarial',
    display_name: 'Adjudicación Notarial',
    description: 'Sucesión tramitada ante notario',
    ownership_mode: 'dividido',
    sort_order: 23
  },

  # Donaciones
  {
    name: 'donacion_simple',
    display_name: 'Donación Simple',
    description: 'Transferencia voluntaria sin contraprestación',
    ownership_mode: 'único',
    sort_order: 30
  },
  {
    name: 'donacion_condicional',
    display_name: 'Donación Condicional',
    description: 'Donación sujeta a condiciones específicas',
    ownership_mode: 'único',
    sort_order: 31
  },

  # Sociedades
  {
    name: 'sociedad_mercantil',
    display_name: 'Sociedad Mercantil',
    description: 'Propiedad de sociedad constituida (S.A., S. de R.L.)',
    ownership_mode: 'dividido',
    sort_order: 40
  },
  {
    name: 'copropiedad_accionaria',
    display_name: 'Copropiedad Accionaria',
    description: 'Propiedad por accionistas de sociedad',
    ownership_mode: 'dividido',
    sort_order: 41
  },

  # Fideicomisos Adicionales
  {
    name: 'fideicomiso_testamentario',
    display_name: 'Fideicomiso Testamentario',
    description: 'Fideicomiso constituido por testamento',
    ownership_mode: 'dividido',
    sort_order: 50
  },

  # Copropiedad
  {
    name: 'copropiedad_comun',
    display_name: 'Copropiedad Común',
    description: 'Propiedad compartida sin vínculo familiar o societario',
    ownership_mode: 'dividido',
    sort_order: 60
  },
  {
    name: 'copropiedad_familiar',
    display_name: 'Copropiedad Familiar',
    description: 'Propiedad compartida entre familiares',
    ownership_mode: 'dividido',
    sort_order: 61
  },

  # Condominio
  {
    name: 'condominio',
    display_name: 'Régimen en Condominio',
    description: 'Propiedad bajo régimen de condominio',
    ownership_mode: 'dividido',
    sort_order: 70
  },

  # Prescripción
  {
    name: 'prescripcion_adquisitiva',
    display_name: 'Prescripción Adquisitiva',
    description: 'Propiedad por posesión continua (10-20 años)',
    ownership_mode: 'único',
    sort_order: 80
  },
  {
    name: 'usucapion',
    display_name: 'Usucapión',
    description: 'Adquisición por posesión pública y pacífica',
    ownership_mode: 'único',
    sort_order: 81
  },

  # Otros
  {
    name: 'dacion_pago',
    display_name: 'Dación en Pago',
    description: 'Propiedad adquirida como pago de deuda',
    ownership_mode: 'único',
    sort_order: 90
  },
  {
    name: 'permuta',
    display_name: 'Permuta',
    description: 'Propiedad por intercambio con otro bien',
    ownership_mode: 'único',
    sort_order: 91
  },
  {
    name: 'sin_especificar',
    display_name: 'Sin Especificar',
    description: 'Tipo desconocido o por definir',
    ownership_mode: 'único',
    sort_order: 999
  }
]

co_ownership_types.each do |type_data|
  co_type = CoOwnershipType.find_or_create_by!(name: type_data[:name]) do |t|
    t.display_name = type_data[:display_name]
    t.description = type_data[:description]
    t.ownership_mode = type_data[:ownership_mode]
    t.sort_order = type_data[:sort_order]
    t.active = true
    t.metadata = {}
    t.minimum_role_level = 30
  end
  
  puts "  ✅ #{co_type.display_name}"
end

puts "\n✅ #{CoOwnershipType.count} tipos de copropiedad activos"

