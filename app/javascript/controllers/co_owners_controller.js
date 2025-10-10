import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item", "totalPercentage", "remainingPercentage", "totalCount"]

  connect() {
    this.updateSummary()
  }

  togglePropertySection(event) {
    const existingSection = document.getElementById('existing-property-section')
    const newSection = document.getElementById('new-property-section')
    
    if (event.target.value === 'existing') {
      existingSection.style.display = 'block'
      newSection.style.display = 'none'
    } else {
      existingSection.style.display = 'none'
      newSection.style.display = 'block'
    }
  }

  addCoOwner() {
    const template = this.itemTargets[0].cloneNode(true)
    
    // Limpiar valores
    template.querySelectorAll('input, select, textarea').forEach(input => {
      if (input.type === 'checkbox') {
        input.checked = false
      } else {
        input.value = ''
      }
    })
    
    // Actualizar IDs y nombres únicos
    const newIndex = this.itemTargets.length
    template.querySelectorAll('[id]').forEach(element => {
      element.id = element.id.replace(/\d+/, newIndex)
    })
    
    this.containerTarget.appendChild(template)
    this.updateSummary()
  }

  removeCoOwner(event) {
    if (this.itemTargets.length > 1) {
      event.target.closest('.co-owner-item').remove()
      this.updateSummary()
    }
  }

  updatePercentages() {
    this.updateSummary()
  }

  updateSummary() {
    const items = this.itemTargets
    let totalPercentage = 0
    
    items.forEach(item => {
      const percentageInput = item.querySelector('input[name*="percentage"]')
      if (percentageInput && percentageInput.value) {
        totalPercentage += parseFloat(percentageInput.value)
      }
    })
    
    if (this.hasTotalPercentageTarget) {
      this.totalPercentageTarget.textContent = `${totalPercentage.toFixed(2)}%`
    }
    if (this.hasRemainingPercentageTarget) {
      this.remainingPercentageTarget.textContent = `${(100 - totalPercentage).toFixed(2)}%`
    }
    if (this.hasTotalCountTarget) {
      this.totalCountTarget.textContent = items.length
    }
  }

  autoSetup() {
    const coOwnershipSelect = document.querySelector('select[name*="co_ownership_type_id"]')
    const selectedOption = coOwnershipSelect.options[coOwnershipSelect.selectedIndex]
    
    if (!selectedOption.value) {
      alert('Primero seleccione un tipo de copropiedad')
      return
    }
    
    // Limpiar copropietarios existentes excepto el primero
    const items = this.itemTargets
    for (let i = items.length - 1; i > 0; i--) {
      items[i].remove()
    }
    
    // Configurar según tipo
    const typeName = selectedOption.textContent.toLowerCase()
    
    if (typeName.includes('individual') || typeName.includes('único')) {
      this.setupIndividual()
    } else if (typeName.includes('mancomunado') || typeName.includes('matrimon')) {
      this.setupMancomunados()
    } else if (typeName.includes('herencia') || typeName.includes('heredero')) {
      this.setupHerencia()
    }
    
    this.updateSummary()
  }

  setupIndividual() {
    const firstItem = this.itemTargets[0]
    const percentageInput = firstItem.querySelector('input[name*="percentage"]')
    const roleSelect = firstItem.querySelector('select[name*="role"]')
    
    if (percentageInput) percentageInput.value = '100'
    if (roleSelect) roleSelect.value = 'propietario'
  }

  setupMancomunados() {
    // Primer copropietario
    const firstItem = this.itemTargets[0]
    const firstPercentage = firstItem.querySelector('input[name*="percentage"]')
    const firstRole = firstItem.querySelector('select[name*="role"]')
    
    if (firstPercentage) firstPercentage.value = '50'
    if (firstRole) firstRole.value = 'conyuge'
    
    // Agregar segundo copropietario
    this.addCoOwner()
    
    const secondItem = this.itemTargets[1]
    const secondPercentage = secondItem.querySelector('input[name*="percentage"]')
    const secondRole = secondItem.querySelector('select[name*="role"]')
    
    if (secondPercentage) secondPercentage.value = '50'
    if (secondRole) secondRole.value = 'conyuge'
  }

  setupHerencia() {
    // Agregar segundo heredero
    this.addCoOwner()
    
    // Configurar ambos como herederos
    this.itemTargets.forEach(item => {
      const roleSelect = item.querySelector('select[name*="role"]')
      if (roleSelect) roleSelect.value = 'heredero'
    })
  }

  updateClientName(event) {
    const clientSelect = event.target
    const coOwnerItem = clientSelect.closest('.co-owner-item')
    const nameInput = coOwnerItem.querySelector('input[name*="person_name"]')
    
    if (clientSelect.value && nameInput) {
      const selectedText = clientSelect.options[clientSelect.selectedIndex].text
      nameInput.value = selectedText
    }
  }
}
