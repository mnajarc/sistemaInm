puts "🌱 Creando métodos de adquisición de propiedades..."

methods = [
  {
    name: 'Compraventa tradicional',
    code: 'compraventa',
    legal_reference: 'Código Civil Federal Art. 2248-2326',
    legal_act_type: 'compraventa',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 1
  },
  {
    name: 'Compraventa de derechos de propiedad',
    code: 'compraventa_derechos',
    legal_reference: 'Código Civil Federal Art. 2249-2250',
    legal_act_type: 'compraventa_derechos',
    requires_heirs: false,
    requires_coowners: true,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 2
  },
  {
    name: 'Herencia o Sucesión',
    code: 'herencia',
    legal_reference: 'Código Civil Federal Art. 1281-1791',
    legal_act_type: 'herencia',
    requires_heirs: true,
    requires_coowners: true,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 3
  },
  {
    name: 'Donación',
    code: 'donacion',
    legal_reference: 'Código Civil Federal Art. 2332-2380',
    legal_act_type: 'donacion',
    requires_heirs: false,
    requires_coowners: true,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 4
  },
  {
    name: 'Permuta',
    code: 'permuta',
    legal_reference: 'Código Civil Federal Art. 2327-2330',
    legal_act_type: 'permuta',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 5
  },
  {
    name: 'Cesión de derechos',
    code: 'cesion_derechos',
    legal_reference: 'Código Civil Federal Art. 2029-2050',
    legal_act_type: 'cesion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: false,
    requires_power_of_attorney: false,
    sort_order: 6
  },
  {
    name: 'Adjudicación Judicial',
    code: 'adjudicacion_judicial',
    legal_reference: 'Código de Procedimientos Civiles',
    legal_act_type: 'adjudicacion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: false,
    requires_power_of_attorney: false,
    sort_order: 7
  },
  {
    name: 'Usucapión (Prescripción Positiva)',
    code: 'usucapion',
    legal_reference: 'Código Civil Federal Art. 1135-1150',
    legal_act_type: 'usucapion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 8
  },
  {
    name: 'Prescripción Negativa (Liberatoria)',
    code: 'prescripcion_negativa',
    legal_reference: 'Código Civil Federal Art. 1158-1180',
    legal_act_type: 'prescripcion_negativa',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 9
  },
  {
    name: 'Dación en Pago',
    code: 'dacion_pago',
    legal_reference: 'Código Civil Federal Art. 2095-2100',
    legal_act_type: 'dacion_pago',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 10
  },
  {
    name: 'Fideicomiso',
    code: 'fideicomiso',
    legal_reference: 'Ley General de Títulos y Operaciones de Crédito Art. 381-408',
    legal_act_type: 'fideicomiso',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 11
  },
  {
    name: 'Aportación a Sociedad',
    code: 'aportacion_sociedad',
    legal_reference: 'Ley General de Sociedades Mercantiles',
    legal_act_type: 'aportacion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 12
  },
  {
    name: 'Cooperativas y Asociaciones Civiles',
    code: 'cooperativa',
    legal_reference: 'Ley General de Sociedades Cooperativas',
    legal_act_type: 'cooperativa',
    requires_heirs: false,
    requires_coowners: true,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 13
  },
  {
    name: 'Arrendamiento con Opción a Compra',
    code: 'arrendamiento_opcion',
    legal_reference: 'Código Civil Federal Art. 2398-2430',
    legal_act_type: 'arrendamiento_opcion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: false,
    requires_power_of_attorney: false,
    sort_order: 14
  },
  {
    name: 'Venta Judicial',
    code: 'venta_judicial',
    legal_reference: 'Código de Procedimientos Civiles',
    legal_act_type: 'venta_judicial',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 15
  },
  {
    name: 'Expropiación',
    code: 'expropiacion',
    legal_reference: 'Ley de Expropiación',
    legal_act_type: 'expropiacion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 16
  },
  {
    name: 'Fusión/Escisión de Sociedades',
    code: 'fusion_escision',
    legal_reference: 'Ley General de Sociedades Mercantiles Art. 222-228',
    legal_act_type: 'fusion_escision',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 17
  },
  {
    name: 'Sentencia Arbitral',
    code: 'sentencia_arbitral',
    legal_reference: 'Código de Comercio Art. 1415-1480',
    legal_act_type: 'sentencia_arbitral',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: true,
    requires_notary: true,
    requires_power_of_attorney: false,
    sort_order: 18
  },
  {
    name: 'Accesión',
    code: 'accesion',
    legal_reference: 'Código Civil Federal Art. 908-945',
    legal_act_type: 'accesion',
    requires_heirs: false,
    requires_coowners: false,
    requires_judicial_sentence: false,
    requires_notary: false,
    requires_power_of_attorney: false,
    sort_order: 19
  }
]

methods.each do |method|
  PropertyAcquisitionMethod.find_or_create_by!(code: method[:code]) do |m|
    m.assign_attributes(method)
  end
end

puts "✅ #{PropertyAcquisitionMethod.count} métodos de adquisición creados"

