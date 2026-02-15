require 'rails_helper'

RSpec.describe InitialContactForm, type: :model do
  # Setup básico
  let(:agent) { Agent.first || create(:agent) }
  let(:operation_type) { OperationType.first || create(:operation_type, name: 'venta') }
  
  describe 'validaciones' do
    it 'requiere un agente' do
      icf = InitialContactForm.new(agent: nil)
      expect(icf).not_to be_valid
      expect(icf.errors[:agent_id]).to include("can't be blank")
    end
    
    it 'requiere un status' do
      icf = InitialContactForm.new(agent: agent, status: nil)
      expect(icf).not_to be_valid
      expect(icf.errors[:status]).to include("can't be blank")
    end
  end
  
  describe 'callbacks' do
    it 'genera initial_contact_folio automáticamente' do
      icf = InitialContactForm.create!(
        agent: agent,
        status: :draft
      )
      
      expect(icf.initial_contact_folio).to be_present
      expect(icf.initial_contact_folio).to match(/^[A-Z]{2,3}\d{6}_\d{2}$/)
    end
    
    it 'inicializa acquisition_details con co_owners_count = 1' do
      icf = InitialContactForm.new(agent: agent)
      expect(icf.acquisition_details['co_owners_count']).to eq(1)
    end
  end
  
  describe '#find_or_create_client!' do
    let(:icf) do
      InitialContactForm.create!(
        agent: agent,
        status: :draft,
        general_conditions: {
          'first_names' => 'Juan Alberto',
          'first_surname' => 'Espinoza',
          'second_surname' => 'Cruz',
          'owner_email' => 'juan.test@example.com',
          'owner_phone' => '5512345678'
        }
      )
    end
    
    it 'crea un nuevo cliente si no existe' do
      expect {
        client = icf.find_or_create_client!
        expect(client).to be_persisted
        expect(client.email).to eq('juan.test@example.com')
        expect(client.full_name).to include('Juan Alberto')
      }.to change(Client, :count).by(1)
    end
    
    it 'retorna cliente existente si ya está registrado' do
      # Crear cliente previamente
      existing = Client.create!(
        first_names: 'Juan Alberto',
        first_surname: 'Espinoza',
        email: 'juan.test@example.com'
      )
      
      expect {
        client = icf.find_or_create_client!
        expect(client.id).to eq(existing.id)
      }.not_to change(Client, :count)
    end
    
    it 'retorna false si faltan datos obligatorios' do
      icf.general_conditions = { 'first_names' => 'Juan' } # Sin apellido ni email
      
      result = icf.find_or_create_client!
      expect(result).to be_falsey
    end
  end
  
  describe '#has_co_owners?' do
    it 'retorna true si co_owners_count > 1' do
      icf = InitialContactForm.new(
        agent: agent,
        acquisition_details: { 'co_owners_count' => 3 }
      )
      
      expect(icf.has_co_owners?).to be true
    end
    
    it 'retorna false si co_owners_count = 1' do
      icf = InitialContactForm.new(
        agent: agent,
        acquisition_details: { 'co_owners_count' => 1 }
      )
      
      expect(icf.has_co_owners?).to be false
    end
  end
  
  describe 'scopes' do
    before do
      # Crear algunos ICFs de prueba
      @draft_icf = InitialContactForm.create!(agent: agent, status: :draft)
      @completed_icf = InitialContactForm.create!(agent: agent, status: :completed)
      @converted_icf = InitialContactForm.create!(agent: agent, status: :converted)
    end
    
    it '.pending_conversion retorna solo completados sin transacción' do
      expect(InitialContactForm.pending_conversion).to include(@completed_icf)
      expect(InitialContactForm.pending_conversion).not_to include(@draft_icf)
      expect(InitialContactForm.pending_conversion).not_to include(@converted_icf)
    end
  end
end

