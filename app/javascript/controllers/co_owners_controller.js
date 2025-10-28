import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item", "totalPercentage", "remainingPercentage", "totalCount"]

  connect() {
    console.log('✅ Co-owners controller conectado')
    this.updateSummary()
  }

  updateCoOwnershipType(event) {
    console.log('📌 Tipo de copropiedad cambiado:', event.target.value)
  }

  addCoOwner(event) {
    if (event) event.preventDefault()

    if (this.itemTargets.length === 0) {
      console.warn('⚠️ No hay template')
      return
    }

    const template = this.itemTargets[0].cloneNode(true)
    template.querySelectorAll('input, select').forEach(input => {
      if (input.type === 'checkbox') {
        input.checked = false
      } else {
        input.value = ''
      }
    })

    const newIndex = this.itemTargets.length
    template.querySelectorAll('[id]').forEach(el => {
      el.id = el.id.replace(/\d+/, newIndex)
    })

    this.containerTarget.appendChild(template)
    this.updateSummary()
  }

  removeCoOwner(event) {
    event.preventDefault()
    if (this.itemTargets.length > 1) {
      event.target.closest('.co-owner-item').remove()
      this.updateSummary()
    }
  }

  updatePercentages() {
    this.updateSummary()
  }

  updateSummary() {
    let total = 0
    this.itemTargets.forEach(item => {
      const input = item.querySelector('input[name*="percentage"]')
      if (input && input.value) {
        total += parseFloat(input.value)
      }
    })

    if (this.hasTotalPercentageTarget) {
      this.totalPercentageTarget.textContent = `${total.toFixed(2)}%`
    }
    if (this.hasRemainingPercentageTarget) {
      this.remainingPercentageTarget.textContent = `${(100 - total).toFixed(2)}%`
    }
    if (this.hasTotalCountTarget) {
      this.totalCountTarget.textContent = this.itemTargets.length
    }
  }

  autoSetup(event) {
    event.preventDefault()
    const select = document.querySelector('select[name*="co_ownership_type_id"]')
    
    if (!select || !select.value) {
      alert('⚠️ Seleccione un tipo de copropiedad')
      return
    }

    const firstItem = this.itemTargets[0]
    const pct = firstItem.querySelector('input[name*="percentage"]')
    const role = firstItem.querySelector('select[name*="role"]')

    if (pct) pct.value = '100'
    if (role) role.value = 'propietario'

    this.updateSummary()
  }

  updateClientName(event) {
    const select = event.target
    const item = select.closest('.co-owner-item')
    const nameInput = item.querySelector('input[name*="person_name"]')

    if (select.value && nameInput) {
      nameInput.value = select.options[select.selectedIndex].text
    }
  }
}
