# spec/models/business_transaction_co_owner_consistency_spec.rb
#
# Estas pruebas verifican la consistencia entre offering_client_id/acquiring_client_id
# y los registros en business_transaction_co_owners.
#
# CONTEXTO: offering_client_id es un vestigio del diseño original (1 propietario).
# La fuente de verdad son los co_owners. Estas pruebas detectan inconsistencias.

require 'rails_helper'

RSpec.describe 'BusinessTransaction - Consistencia Copropietarios', type: :model do
  # ================================================================
  # SETUP COMPARTIDO
  # ================================================================

  let(:agent_user) { create(:user, :agent) }
  let(:client_principal) { create(:client) }
  let(:operation_type) { create(:operation_type, name: 'venta') }
  let(:business_status) { create(:business_status, name: 'available') }
  let(:property) { create(:property, user: agent_user) }

  let(:base_bt_attrs) do
    {
      listing_agent: agent_user,
      current_agent: agent_user,
      offering_client: client_principal,
      property: property,
      operation_type: operation_type,
      business_status: business_status,
      price: 1_000_000,
      start_date: Date.current,
      commission_percentage: 5.0
    }
  end

  # ================================================================
  # PROPIETARIO PRINCIPAL = COPROPIETARIO AL 100%
  # ================================================================

  describe 'Propietario único (copropietario al 100%)' do
    let(:bt) { BusinessTransaction.create!(base_bt_attrs) }

    before do
      bt.business_transaction_co_owners.create!(
        client: client_principal,
        person_name: client_principal.full_name,
        role: 'propietario',
        percentage: 100.0,
        active: true
      )
    end

    it 'offering_client coincide con el copropietario principal' do
      principal_co_owner = bt.business_transaction_co_owners
                             .where(role: 'propietario', active: true)
                             .first

      expect(principal_co_owner).to be_present
      expect(principal_co_owner.client_id).to eq(bt.offering_client_id),
        "INCONSISTENCIA: offering_client_id (#{bt.offering_client_id}) " \
        "no coincide con copropietario principal (#{principal_co_owner.client_id})"
    end

    it 'porcentaje total es 100%' do
      total = bt.business_transaction_co_owners.active.sum(:percentage)
      expect(total).to eq(100.0)
    end

    it 'solo hay un copropietario activo' do
      expect(bt.business_transaction_co_owners.active.count).to eq(1)
    end

    it 'is_single_owner? retorna true' do
      expect(bt.is_single_owner?).to be true
    end
  end

  # ================================================================
  # MÚLTIPLES COPROPIETARIOS
  # ================================================================

  describe 'Múltiples copropietarios' do
    let(:client_copropietario) { create(:client) }
    let(:bt) { BusinessTransaction.create!(base_bt_attrs) }

    before do
      bt.business_transaction_co_owners.create!(
        client: client_principal,
        person_name: client_principal.full_name,
        role: 'propietario',
        percentage: 60.0,
        active: true
      )
      bt.business_transaction_co_owners.create!(
        client: client_copropietario,
        person_name: client_copropietario.full_name,
        role: 'copropietario',
        percentage: 40.0,
        active: true
      )
    end

    it 'offering_client es el copropietario principal (no el único)' do
      principal = bt.business_transaction_co_owners
                    .where(role: 'propietario', active: true)
                    .first

      expect(principal.client_id).to eq(bt.offering_client_id)
    end

    it 'porcentajes suman 100%' do
      total = bt.business_transaction_co_owners.active.sum(:percentage)
      expect(total.round(2)).to eq(100.0)
    end

    it 'is_single_owner? retorna false' do
      expect(bt.is_single_owner?).to be false
    end

    it 'total_ownership_percentage es 100' do
      expect(bt.total_ownership_percentage.round(2)).to eq(100.0)
    end
  end

  # ================================================================
  # ESCENARIO: COPROPIETARIO PRINCIPAL FALLECE
  # ================================================================

  describe 'Cambio de copropietario principal (fallecimiento)' do
    let(:client_copropietario) { create(:client) }
    let(:bt) { BusinessTransaction.create!(base_bt_attrs) }

    before do
      @co_owner_principal = bt.business_transaction_co_owners.create!(
        client: client_principal,
        person_name: client_principal.full_name,
        role: 'propietario',
        percentage: 50.0,
        active: true
      )
      @co_owner_secundario = bt.business_transaction_co_owners.create!(
        client: client_copropietario,
        person_name: client_copropietario.full_name,
        role: 'copropietario',
        percentage: 50.0,
        active: true
      )
    end

    it 'al desactivar principal, offering_client queda inconsistente' do
      # Simular "fallecimiento": desactivar copropietario principal
      @co_owner_principal.update!(active: false)

      # El copropietario activo ahora es solo el secundario
      activos = bt.business_transaction_co_owners.where(active: true)
      expect(activos.count).to eq(1)
      expect(activos.first.client_id).to eq(client_copropietario.id)

      # PERO offering_client_id sigue apuntando al fallecido
      # ESTA ES LA INCONSISTENCIA QUE DOCUMENTAMOS
      expect(bt.offering_client_id).to eq(client_principal.id)
      expect(bt.offering_client_id).not_to eq(activos.first.client_id),
        "NOTA: Si este test FALLA, significa que ya se corrigió " \
        "la sincronización automática (lo cual es bueno)"
    end

    it 'porcentajes quedan en 50% (necesitan redistribución manual)' do
      @co_owner_principal.update!(active: false)
      total = bt.business_transaction_co_owners.active.sum(:percentage)

      # Después de desactivar, solo queda 50% — NECESITA INTERVENCIÓN
      expect(total).to eq(50.0)
      expect(total).not_to eq(100.0),
        "Los porcentajes deben redistribuirse manualmente tras un cambio de principal"
    end
  end

  # ================================================================
  # ESCENARIO: CONVERSIÓN DESDE ICF
  # ================================================================

  describe 'Conversión ICF → BT mantiene consistencia' do
    # Este test asume que tienes un ICF válido para conversión.
    # Si tus factories lo soportan, descomenta y ajusta.

    xit 'offering_client coincide con primer copropietario creado' do
      icf = create(:initial_contact_form, :completed_for_conversion,
                   agent: agent_user.agent)
      bt = icf.convert_to_transaction!

      expect(bt).to be_present
      expect(bt).to be_a(BusinessTransaction)

      principal = bt.business_transaction_co_owners
                    .where(role: 'propietario', active: true)
                    .first

      expect(principal).to be_present
      expect(principal.client_id).to eq(bt.offering_client_id)
    end
  end

  # ================================================================
  # HELPER: Detectar inconsistencias en batch (para rake task)
  # ================================================================

  describe 'Detección de inconsistencias (auditoría)' do
    it 'identifica BTs donde offering_client no está en co_owners' do
      bt = BusinessTransaction.create!(base_bt_attrs)

      # Crear co_owner con un client DIFERENTE al offering_client
      other_client = create(:client)
      bt.business_transaction_co_owners.create!(
        client: other_client,
        person_name: other_client.full_name,
        role: 'propietario',
        percentage: 100.0,
        active: true
      )

      # Detectar la inconsistencia
      co_owner_client_ids = bt.business_transaction_co_owners
                               .active
                               .pluck(:client_id)
                               .compact

      is_consistent = co_owner_client_ids.include?(bt.offering_client_id)

      expect(is_consistent).to be false,
        "DETECTADA: offering_client_id=#{bt.offering_client_id} " \
        "no está entre los co_owners activos: #{co_owner_client_ids}"
    end
  end
end
