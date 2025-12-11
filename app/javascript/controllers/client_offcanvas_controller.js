import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["offcanvas"]

  connect() {
    console.log('✅ ClientOffcanvas controller connected')
    
    // Inicializar offcanvas
    this.showOffcanvas()
    
    // Listeners
    this.setupEventListeners()
  }

  showOffcanvas() {
    const offcanvasElement = document.getElementById('clientOffcanvas')
    if (offcanvasElement) {
      const offcanvas = new bootstrap.Offcanvas(offcanvasElement)
      offcanvas.show()
      console.log('✅ Offcanvas shown')
    } else {
      console.error('❌ Offcanvas element not found')
    }
  }

  setupEventListeners() {
    const civilStatusField = document.getElementById('civilStatusField')
    const marriageRegimeField = document.getElementById('marriageRegimeField')
    const ownerNameInput = document.getElementById('ownerName')
    const saveBtn = document.getElementById('saveClientBtn')

    // Mostrar/ocultar régimen matrimonial
    if (civilStatusField) {
      civilStatusField.addEventListener('change', (e) => {
        if (marriageRegimeField) {
          marriageRegimeField.style.display = e.target.value === 'casado' ? 'block' : 'none'
        }
      })
    }

    // Actualizar preview del Opportunity ID
    if (ownerNameInput) {
      ownerNameInput.addEventListener('input', () => this.updateOpportunityPreview())
    }

    // Guardar cliente
    if (saveBtn) {
      saveBtn.addEventListener('click', () => this.saveClient())
    }
  }

  updateOpportunityPreview() {
    const ownerNameInput = document.getElementById('ownerName')
    const opportunityPreview = document.getElementById('opportunityPreview')
    
    if (!ownerNameInput || !opportunityPreview) return

    const nameInput = ownerNameInput.value.trim()
    if (!nameInput) return

    const nameParts = nameInput.split(/\s+/)
    const lastName = nameParts.length >= 2 ? nameParts : nameParts
    const lastNameClean = lastName.toUpperCase().substring(0, 10)
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    
    opportunityPreview.textContent = `V-${lastNameClean}-${today}-001`
  }

  saveClient() {
    const ownerNameInput = document.getElementById('ownerName')
    const ownerPhoneInput = document.getElementById('ownerPhone')
    const ownerEmailInput = document.getElementById('ownerEmail')
    const civilStatusField = document.getElementById('civilStatusField')
    const marriageRegimeSelect = document.getElementById('marriageRegimeSelect')
    const clientNotes = document.getElementById('clientNotes')
    const saveBtn = document.getElementById('saveClientBtn')
    const offcanvasElement = document.getElementById('clientOffcanvas')

    if (!ownerNameInput.value.trim()) {
      alert('El nombre del cliente es requerido')
      return
    }

    // Deshabilitar botón mientras se guarda
    saveBtn.disabled = true
    saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span> Guardando...'

    const formData = new FormData()
    formData.append('general_conditions[owner_or_representative_name]', ownerNameInput.value)
    formData.append('general_conditions[owner_phone]', ownerPhoneInput.value)
    formData.append('general_conditions[owner_email]', ownerEmailInput.value)
    formData.append('general_conditions[civil_status]', civilStatusField.value)
    formData.append('general_conditions[marriage_regime_id]', marriageRegimeSelect.value)
    formData.append('general_conditions[notes]', clientNotes.value)

    // Obtener la ruta del formulario
    const formId = document.querySelector('form[data-form-id]')?.dataset.formId
    if (!formId) {
      console.error('Form ID not found')
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/initial_contact_forms/${formId}/update_client_from_modal`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: formData
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)
      return response.json()
    })
    .then(data => {
      console.log('✅ Client saved:', data)
      
      // Actualizar campos en el formulario principal
      this.updateMainFormFields()

      // Cerrar offcanvas
      const offcanvas = bootstrap.Offcanvas.getInstance(offcanvasElement)
      if (offcanvas) {
        offcanvas.hide()
      }

      // Mostrar toast de éxito
      this.showSuccessToast()

      // Recargar el formulario principal para reflejar cambios
      setTimeout(() => {
        window.location.reload()
      }, 1500)
    })
    .catch(error => {
      console.error('❌ Error saving client:', error)
      alert('Error al guardar el cliente: ' + error.message)
      saveBtn.disabled = false
      saveBtn.innerHTML = '<i class="bi bi-check-lg"></i> Guardar Cliente'
    })
  }

  updateMainFormFields() {
    const ownerNameInput = document.getElementById('ownerName')
    const ownerPhoneInput = document.getElementById('ownerPhone')
    const ownerEmailInput = document.getElementById('ownerEmail')

    // Buscar el formulario principal
    const mainForm = document.querySelector('form.initial-contact-form')
    if (mainForm) {
      const nameField = mainForm.querySelector('input[name="initial_contact_form[general_conditions][owner_or_representative_name]"]')
      const phoneField = mainForm.querySelector('input[name="initial_contact_form[general_conditions][owner_phone]"]')
      const emailField = mainForm.querySelector('input[name="initial_contact_form[general_conditions][owner_email]"]')

      if (nameField) nameField.value = ownerNameInput.value
      if (phoneField) phoneField.value = ownerPhoneInput.value
      if (emailField) emailField.value = ownerEmailInput.value

      console.log('✅ Main form fields updated')
    }
  }

  showSuccessToast() {
    const toastHTML = `
      <div class="toast align-items-center text-white bg-success border-0" role="alert">
        <div class="d-flex">
          <div class="toast-body">
            <i class="bi bi-check-circle-fill me-2"></i> Cliente actualizado correctamente
          </div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
      </div>
    `

    const container = document.createElement('div')
    container.className = 'toast-container position-fixed bottom-0 end-0 p-3'
    container.innerHTML = toastHTML
    document.body.appendChild(container)

    const toastElement = container.querySelector('.toast')
    const toast = new bootstrap.Toast(toastElement)
    toast.show()
  }
}
