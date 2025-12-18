import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("✅ InitialContactForm Conditional Fields initialized")
    this.initializeConditionalFields()
  }

  initializeConditionalFields() {
    // Herencia - Testamentaria
    const hasTestamentarySelect = document.getElementById('has_testamentary_select')
    const noTestamentaryField = document.getElementById('no-testamentary-field')
    const yesTestamentaryField = document.getElementById('yes-testamentary-field')

    if (hasTestamentarySelect) {
      hasTestamentarySelect.addEventListener('change', () => {
        noTestamentaryField.style.display = hasTestamentarySelect.value === 'false' ? 'block' : 'none'
        yesTestamentaryField.style.display = hasTestamentarySelect.value === 'true' ? 'block' : 'none'
        this.updateRequiredFields()
      })
      // Ejecutar al cargar por si hay valor guardado
      hasTestamentarySelect.dispatchEvent(new Event('change'))
    }
  }

  updateRequiredFields() {
    const yesTestamentaryField = document.getElementById('yes-testamentary-field')
    if (yesTestamentaryField.style.display === 'block') {
      const selects = yesTestamentaryField.querySelectorAll('select[data-originally-required]')
      selects.forEach(select => select.setAttribute('required', 'required'))
    }
  }
}

